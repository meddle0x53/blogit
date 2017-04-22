defmodule Blogit do
  use Application

  alias Blogit.Components.Posts
  alias Blogit.Components.PostsByDate
  alias Blogit.Components.Configuration

  @repository_provider Application.get_env(
    :blogit, :repository_provider, Blogit.RepositoryProviders.Git
  )

  def start(_type, _args) do
    Blogit.Supervisor.start_link(@repository_provider)
  end

  def list_posts(from \\ 0, size \\ 5) do
    GenServer.call(Posts, {:list, from, size})
  end

  def list_pinned(), do: GenServer.call(Posts, :list_pinned)

  def filter_posts(params, from \\ 0, size \\ 5) do
    GenServer.call(Posts, {:filter, params, from, size})
  end

  def posts_by_dates, do: GenServer.call(PostsByDate, :get)

  def post_by_name(name), do: GenServer.call(Posts, {:by_name, name})

  def configuration do
    GenServer.call(Configuration, :get)
  end
end
