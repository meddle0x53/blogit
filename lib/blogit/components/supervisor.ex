defmodule Blogit.Components.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: supervise([], [strategy: :one_for_one])
end
