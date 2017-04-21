defmodule Blogit.Components.PostsByDate do
  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Components.Posts

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_cast(:stop, posts_by_dates) do
    {:stop, :normal, posts_by_dates}
  end

  def handle_call(:get, _from, nil) do
    posts = GenServer.call(Posts, :all)

    posts_by_dates = Post.collect_by_year_and_month(posts)
    {:reply, posts_by_dates, posts_by_dates}
  end

  def handle_call(:get, _from, posts_by_dates) do
    {:reply, posts_by_dates, posts_by_dates}
  end
end
