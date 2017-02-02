defmodule Blogit do
  use Application

  alias Blogit.Worker

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Worker, [Blogit.Worker]),
    ]

    opts = [strategy: :one_for_one, name: Blogit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def list_posts, do: GenServer.call(Worker, :list_posts)

  def posts_by_dates, do: GenServer.call(Worker, :posts_by_dates)

  def search_posts(query), do: GenServer.call(Worker, {:search_posts, query})

  def post_by_name(name), do: GenServer.call(Worker, {:post_by_name, name})

  def configuration, do: GenServer.call(Worker, :blog_configuration)
end
