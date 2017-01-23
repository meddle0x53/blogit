defmodule Blogit do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Blogit.Worker, [Blogit.Worker]),
    ]

    opts = [strategy: :one_for_one, name: Blogit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def list_posts, do: GenServer.call(Blogit.Worker, :list_posts)

  def post_by_name(name) do
    GenServer.call(Blogit.Worker, {:post_by_name, name})
  end

  def configuration, do: GenServer.call(Blogit.Worker, :blog_configuration)
end
