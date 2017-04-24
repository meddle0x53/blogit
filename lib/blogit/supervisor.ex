defmodule Blogit.Supervisor do
  use Supervisor

  def start_link(repository_provider) do
    Supervisor.start_link(__MODULE__, repository_provider, name: __MODULE__)
  end

  def init(repository_provider) do
    children = [
      supervisor(Blogit.Components.Supervisor, []),
      supervisor(Task.Supervisor, [[name: :tasks_supervisor]]),
      worker(Blogit.Server, [repository_provider])
    ]

    opts = [strategy: :one_for_all]

    supervise(children, opts)
  end
end
