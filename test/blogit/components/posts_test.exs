defmodule Blogit.Components.PostsTest do
  alias Blogit.Components.Posts
  use ComponentTestCase, setup_posts: true, module: Posts

  setup %{posts_pid: pid}, do: %{pid: pid}

  test "`posts` state is calculated from the posts_provider", %{pid: pid} do
    %{language: language, posts: posts} = :sys.get_state(pid)

    assert language == Settings.default_language()
    refute is_nil(posts)

    post_names = posts |> Map.keys()

    expected_post_names = [
      :control_flow_and_errors,
      :mix,
      :modules_functions_recursion,
      :nodes,
      :otp,
      :plug,
      :processes
    ]

    assert expected_post_names
           |> Enum.all?(fn name ->
             post_names |> Enum.member?(name)
           end)
  end

  test "cast `{:update, map-of-posts}`, overides the posts", %{pid: pid} do
    GenServer.cast(pid, {:update, %{one: "a-post"}})

    %{posts: posts} = :sys.get_state(pid)

    assert posts |> Map.keys() == [:one]
  end

  test "call `:all`, returns a list of all posts Blogit.Models.Post structs", %{pid: pid} do
    posts = GenServer.call(pid, :all)

    post_names = posts |> Enum.map(& &1.meta.name)

    expected_post_names = ~w[
      control_flow_and_errors mix modules_functions_recursion nodes otp plug
      processes
    ]

    assert expected_post_names
           |> Enum.all?(fn name ->
             post_names |> Enum.member?(name)
           end)

    assert Map.get(List.first(posts), :__struct__) == Blogit.Models.Post
  end

  test "call `{:filter, filters, from, size}`, returns list of filtered " <>
         "posts as Blogit.Models.Post.Meta structs, sorted by creation",
       %{pid: pid} do
    posts = GenServer.call(pid, {:filter, %{"author" => "meddle"}, 1, 1})

    post_names = posts |> Enum.map(& &1.name)
    expected_post_names = ~w(otp)

    assert expected_post_names == post_names
    assert Map.get(List.first(posts), :__struct__) == Blogit.Models.Post.Meta
  end

  test "call `{:filter, filters, from, size}`, returns list of filtered " <>
         "posts as Blogit.Models.Post.Meta structs, sorted by creation; " <>
         "if `:infinity` is passed as `size` all the filtered posts are returned",
       %{pid: pid} do
    posts = GenServer.call(pid, {:filter, %{"author" => "meddle"}, 0, :infinity})

    post_names = posts |> Enum.map(& &1.name)
    expected_post_names = ~w(processes otp nodes)

    assert expected_post_names == post_names
  end

  test "call `{:by_name, name}`, returns %{ok, post} if post is found." <>
         "The post is in the form of `Blogit.Models.Post` struct",
       %{pid: pid} do
    {:ok, post} = GenServer.call(pid, {:by_name, :nodes})

    refute is_nil(post)
    assert Map.get(post, :__struct__) == Blogit.Models.Post

    assert post.html ==
             "<p> Some text…</p>\n<h2>Section 1</h2>\n" <>
               "<p> Hey!!</p>\n<ul>\n<li>i1\n</li>\n<li>i2\n</li>\n</ul>\n"
  end

  test "call `{:by_name, name}`, returns %{:error, post-not-found-message} " <>
         "if post is nod found.",
       %{pid: pid} do
    {:error, message} = GenServer.call(pid, {:by_name, :some})

    assert message == "No post with name some found."
  end
end
