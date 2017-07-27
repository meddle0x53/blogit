defmodule BlogitTest do
  use ExUnit.Case

  alias Blogit.RepositoryProviders.Memory

  defp wait_for_update do
    updated = Agent.get(Memory, fn data -> Enum.empty?(data.updates) end)

    case updated do
      true -> Process.sleep(200)
      false ->
        Process.sleep(100)
        wait_for_update()
    end
  end

  setup_all do
    {:ok, _} = Application.ensure_all_started(:blogit)

    :sys.get_state(Process.whereis(Blogit.Server))

    path = &(Path.join(Blogit.Settings.posts_folder(), &1.path))
    Agent.update(Memory, fn data ->
      %{data |
        raw_posts: Fixtures.posts(),
        updates: Enum.map(Fixtures.posts(), path)
      }
    end)

    send(Process.whereis(Blogit.Server), :check_updates)
    wait_for_update()

    on_exit fn ->
      Application.stop(:blogit)
      Process.sleep(500)
    end

    :ok
  end

  describe ".list_posts" do
    test "by default returns all the posts, newest first" do
      names = Blogit.list_posts() |> Enum.map(&(&1.name))

      assert names == ~w[
        processes plug otp nodes modules_functions_recursion
        mix control_flow_and_errors
      ]
    end

    test """
    returns all posts (newest first) if the option `:size` is passed as `:infinity`
    """ do
      names = [size: :infinity] |> Blogit.list_posts() |> Enum.map(&(&1.name))

      assert names == ~w[
        processes plug otp nodes modules_functions_recursion
        mix control_flow_and_errors
      ]
    end

    test "returns all posts beginning from the given position, newest first" do
      names = [from: 2] |> Blogit.list_posts() |> Enum.map(&(&1.name))

      assert names == ~w[
        otp nodes modules_functions_recursion mix control_flow_and_errors
      ]
    end

    test """
    returns N (maximum) posts beginning from the given `:from` position,
    newest first. N is the second argument given.
    """ do
      names = [from: 2, size: 3] |> Blogit.list_posts() |> Enum.map(&(&1.name))

      assert names == ~w[otp nodes modules_functions_recursion]
    end
  end

  describe ".list_pinned" do
    test """
    returns a list of the pinned posts (the ones with pinned: true in their
    meta data), ordered by their last update date. The most recently updated
    first.
    """ do
      names = Blogit.list_pinned() |> Enum.map(&(elem(&1, 0)))

      assert names == ~w[modules_functions_recursion nodes]
    end
  end

  describe ".filter_posts" do
    test "filters posts by author, the list is sorted with newest first" do
      names =
        %{"author" => "valo"} |> Blogit.filter_posts() |> Enum.map(& &1.name)

      assert names == ~w[plug modules_functions_recursion]
    end

    test "filters posts by category, the list is sorted with newest first" do
      names =
        %{"category" => "Some"} |> Blogit.filter_posts() |> Enum.map(& &1.name)

      assert names == ~w[nodes]
    end

    test "filters posts by tags, the list is sorted with newest first" do
      names =
        %{"tags" => ~s[ab,cd]} |> Blogit.filter_posts() |> Enum.map(& &1.name)

      assert names == ~w[otp]
    end

    test "filters posts by year, the list is sorted with newest first" do
      names =
        %{"year" => "2016"} |> Blogit.filter_posts() |> Enum.map(& &1.name)

      assert names == ~w[control_flow_and_errors]
    end

    test "filters posts by month, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"month" => "5"}) |> Enum.map(& &1.name)

      assert names == ~w[mix control_flow_and_errors]
    end

    test "filters posts by query, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"q" => "Stuff"}) |> Enum.map(& &1.name)

      assert names == ~w[processes]
    end

    test "filters posts by multiple types of filters, the list is sorted " <>
    "with newest first" do
      filters = %{"q" => "OTP", "author" => "meddle", "tags" => "ab"}
      names = Blogit.filter_posts(filters) |> Enum.map(& &1.name)

      assert names == ~w[otp]
    end

    test "the list of posts returns all the posts meeting the filtering " <>
    "criteria by default" do
      names = Blogit.filter_posts(%{}) |> Enum.map(& &1.name)

      assert names == ~w[
        processes plug otp nodes modules_functions_recursion mix
        control_flow_and_errors
      ]
    end

    test "the `from` option can be specified as the start position" do
      names = Blogit.filter_posts(%{}, from: 1) |> Enum.map(& &1.name)

      assert names == ~w[
        plug otp nodes modules_functions_recursion mix control_flow_and_errors
     ]
    end

    test "the `size` option can be used to change the default of " <>
      "`:infinity` posts returned" do
      names = Blogit.filter_posts(%{}, from: 2, size: 2) |> Enum.map(& &1.name)

      assert names == ~w[otp nodes]
    end
  end

  describe ".posts_by_date" do
    test "returns a list of tupples of three elements {year, monthe, N}, " <>
    "where N is the number of post for the month of the year. Newest first." do
      posts_by_date = Blogit.posts_by_dates()

      assert posts_by_date == [{2017, 6, 5}, {2017, 5, 1}, {2016, 5, 1}]
    end
  end

  describe ".post_by_name" do
    test "returns a post by its unique identifier - its name" do
      {:ok, post} = Blogit.post_by_name(:otp)

      assert post.name == "otp"
      assert post.meta.author == "meddle"
      assert post.raw == "---\ntags:\n  - ab\n  - cd\n---\nOTP!\n"
    end

    test "returns the atom :error if no post with the given name is found" do
      result = Blogit.post_by_name(:something_else)
      assert result == {:error, "No post with name something_else found."}
    end
  end

  describe ".configuration" do
    alias Blogit.Models.Configuration

    test "returns the blog configuration as Blogit.Models.Configuration" do
      assert Blogit.configuration() == %Configuration{title: "Memory"}
    end
  end

  describe "Blogit.Server" do
    test "the state of the process is all the blog data - " <>
    "the posts and the configuration" do
      %{
        configurations: configuration, posts: posts, repository: repository
      } = :sys.get_state(Blogit.Server)

      assert configuration == Blogit.Settings.languages() |> Enum.map(fn lang ->
        %Blogit.Models.Configuration{title: "Memory", language: lang}
      end)
      assert posts |> Map.values |> Enum.map(&Map.keys/1) == [
       [
         :control_flow_and_errors, :mix, :modules_functions_recursion, :nodes,
         :otp, :plug, :processes
       ], [:mix]
      ]
      assert repository == %Blogit.RepositoryProvider{
        repo: Memory, provider: Memory
      }
    end
  end
end
