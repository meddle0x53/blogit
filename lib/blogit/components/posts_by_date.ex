defmodule Blogit.Components.PostsByDate do
  @moduledoc """
  A `Blogit.Component` process which can be queried from outside.

  This process handles a `:get` message which returns a list of tuples of
  three elements - `{<year>, <month>, <number-of-posts>}`. It is statistics
  data - for this year and this month the blog has N posts.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`. It is lazy, the first time it is queried it computes
  its state by using the `Blogit.Components.Posts` process' state.

  When the posts get updated, this process' state is reset to `nil` and on the
  next request to it, it is re-calculated.
  """

  use Blogit.Component

  alias Blogit.Models.Post
  alias Blogit.Components.Posts

  def init({language, _}) do
    {:ok, %{language: language, posts_by_dates: nil}}
  end

  def handle_cast(:reset, %{language: language}) do
    {:noreply, %{language: language, posts_by_dates: nil}}
  end

  def handle_call(:get, _from, %{posts_by_dates: nil, language: language}) do
    posts = GenServer.call(Posts.name(language), :all)

    posts_by_dates = Post.collect_by_year_and_month(posts)
    state = %{language: language, posts_by_dates: posts_by_dates}
    {:reply, posts_by_dates, state}
  end

  def handle_call(:get, _from, %{posts_by_dates: posts_by_dates} = state) do
    {:reply, posts_by_dates, state}
  end
end
