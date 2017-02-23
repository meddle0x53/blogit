defmodule Blogit do
  use Application

  alias Blogit.Worker

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Worker, [Blogit.Worker]),
      supervisor(Task.Supervisor, [[name: :tasks_supervisor]])
    ]

    opts = [strategy: :one_for_one, name: Blogit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def list_posts, do: GenServer.call(Worker, :list_posts)

  def posts_by_dates, do: GenServer.call(Worker, :posts_by_dates)

  def filter_posts(params), do: GenServer.call(Worker, {:filter_posts, params})

  def post_by_name(name), do: GenServer.call(Worker, {:post_by_name, name})

  def configuration, do: GenServer.call(Worker, :blog_configuration)
end
