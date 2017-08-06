defmodule Blogit.Components.Posts do
  @moduledoc """
  A component `GenServer` process which can be queried from outside.
  The `Blogit.Components.Posts` process holds all the post in the blog as its
  state.

  This process handles the following `call` messages:
  * :all -> returns all the posts of the blog as list of `Blogit.Models.Post`
    structures.
  * {:list, from, size} -> returns a list of posts sorted by their
    meta.created_at field, newest first. The first `from` are dropped and
    the size of the result list is specified by `size`.
  * :list_pinned -> returns a list of `Blogit.Models.Post` structures, sorted
    by their meta.updated_at field, newest first, only if their meta.pinned
    field is `true`.
  * {:filter, filters, from, size} -> returns a list of posts sorted by their
    meta.created_at field, newest first, filtered by the given `filters` and
    the first `from` are dropped. The size of the list is specified by `size`.
  * {:by_name, name} -> returns one post by its unique name. If there is no
    post with the given `name` the atom `:error` is returned.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`.
  When the posts get updated, this process' state is updated by the
  `Blogit.Server` process.

  The `Blogit.Components.PostsByDate` process calculates its state using this
  one.
  """

  use Blogit.Component

  alias Blogit.Models.Post.Meta
  alias Blogit.Logic.Search

  def init(language) do
    send(self(), :init_posts)
    {:ok, %{language: language}}
  end

  def handle_info(:init_posts, %{language: language}) do
    posts = GenServer.call(Blogit.Server, {:get_posts, language})
    {:noreply, %{language: language, posts: posts}}
  end

  def handle_cast({:update, new_posts}, state) do
    {:noreply, %{state | posts: new_posts}}
  end

  def handle_call(:all, _from, %{posts: posts} = state) do
    {:reply, Map.values(posts), state}
  end

  def handle_call(
    {:filter, filters, from, size}, _from, %{posts: posts} = state
  ) do
    take = if size == :infinity, do: map_size(posts), else: size
    result = posts |> Map.values() |> Search.filter_by_params(filters)
             |> Enum.map(&(&1.meta)) |> Meta.sorted()
             |> Enum.drop(from) |> Enum.take(take)

    {:reply, result, state}
  end

  def handle_call({:by_name, name}, _from, %{posts: posts} = state) do
    case post = posts[name] do
      nil -> {:reply, {:error, "No post with name #{name} found."}, state}
      _ -> {:reply, {:ok, post}, state}
    end
  end
end
