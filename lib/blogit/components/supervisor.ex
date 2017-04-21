defmodule Blogit.Components.Supervisor do
  use Supervisor

  alias Blogit.Components.Posts
  alias Blogit.Components.PostsByDate
  alias Blogit.Components.Configuration

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Posts, []),
      worker(Configuration, []),
      worker(PostsByDate, []),
      supervisor(Task.Supervisor, [[name: :tasks_supervisor]])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
