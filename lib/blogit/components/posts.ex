defmodule Blogit.Components.Posts do
  @moduledoc """
  A component GenServer process which can be queried from outside.
  The Blogit.Components.Posts process holds all the post in the blog as its
  state.

  This procss handles the following `call` messages:
  * :all -> returns all the posts of the blog as list of Blogit.Models.Post
    structures.
  * {:list, from, size} -> returns a list of posts sorted by their
    meta.created_at field, newest first. The first `from` are dropped and
    the size of the result list is specified by `size`.
  * :list_pinned -> returns a list of Blogit.Models.Post structures, sorted
    by their meta.updated_at field, newest first, only if their meta.pinned
    field is `true`.
  * {:filter, filters, from, size} -> returns a list of posts sorted by their
    meta.created_at field, newest first, filtered by the given `filters` and
    the first `from` are dropped. The size of the list is specified by `size`.
  * {:by_name, name} -> returns one post by its unique name. If there is no
    post with the given `name` the atom `:error` is returned.

  This component is supervised by Blogit.Components.Supervisor and added to
  it by Blogit.Server.
  When the posts get updated, this process' state is updated by the
  Blogit.Server process.

  The Blogit.Components.PostsByDate process calculates its state using this
  one.
  """

  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Logic.Search

  @doc """
  Starts the GenServer process.

  The process is started and supervised by Blogit.Components.Supervisor and
  the specification of it is added by Blogit.Server.

  The state of the process in the beginning is nil. When the process becomes
  ready to accept messages, it sends the Blogit.Server process a `:get_posts`
  message to retrieve its state - a map with keys atoms representing the
  unique names of the posts and values Blogit.Models.Post structures,
  representing the posts.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :init_posts)
    {:ok, nil}
  end

  def handle_info(:init_posts, nil) do
    posts = GenServer.call(Blogit.Server, :get_posts)
    {:noreply, posts}
  end

  def handle_cast({:update, new_posts}, _) do
    {:noreply, new_posts}
  end

  def handle_call(:all, _from, posts) do
    {:reply, Map.values(posts), posts}
  end

  def handle_call({:list, from, size}, _from, posts) do
    result = Map.values(posts)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, posts}
  end

  def handle_call(:list_pinned, _from, posts) do
    result = Map.values(posts)
             |> Enum.filter(fn post -> post.meta.pinned end)
             |> Post.sorted(:updated_at)
             |> Enum.map(fn post -> {post.name, post.meta.title} end)

    {:reply, result, posts}
  end

  def handle_call({:filter, filters, from, size}, _from, posts) do
    result = Map.values(posts) |> Search.filter_by_params(filters)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, posts}
  end

  def handle_call({:by_name, name}, _from, posts) do
    case post = posts[name] do
      nil -> {:reply, :error, posts}
      _ -> {:reply, post, posts}
    end
  end
end
