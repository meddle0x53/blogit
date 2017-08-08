defmodule Blogit.Components.Posts do
  @moduledoc """
  A `Blogit.Component` process which can be queried from outside.
  The `Blogit.Components.Posts` process holds all the posts in the blog as its
  state.

  This process handles the following `call` messages:
  * :all -> returns all the posts of the blog as list of `Blogit.Models.Post`
    structures.
  * {:filter, filters, from, size} -> returns a list of posts sorted by their
    meta.created_at field, newest first, filtered by the given `filters` and
    the first `from` are dropped. The size of the list is specified by `size`.
    The posts are represented by `Blogit.Models.Post.Meta` structures so they
    can be presented in a stream by showing only their preview.
  * {:by_name, name} -> returns one post by its unique name. If there is no
    post with the given `name` the tuple `{:error, no-post-found-message}`
    is returned. If the post is present, the tuple `{:ok, the-post}` is
    returned. The post is in the for of a `Blogit.Models.Post` struct.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`.
  When the posts get updated, this process' state is updated by the
  `Blogit.Server` process.

  The `Blogit.Components.PostsByDate` and the `Blogit.Components.Metas`
  processes calculate their state using this one.
  """

  use Blogit.Component

  alias Blogit.Models.Post.Meta
  alias Blogit.Logic.Search

  def init({language, posts_provider}) do
    send(self(), {:init_posts, posts_provider})
    {:ok, %{language: language}}
  end

  def handle_info({:init_posts, posts_provider}, %{language: language}) do
    {:noreply, %{language: language, posts: posts_provider.get_posts(language)}}
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
