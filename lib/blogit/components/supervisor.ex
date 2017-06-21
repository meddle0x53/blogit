defmodule Blogit.Components.Supervisor do
  @moduledoc """
  Represents a Supervisor, which supervises the Blogit.Components worker
  processes.

  By default this Supervisor starts with no children.
  Blogit.Supervisor starts a supervisor process implementing this module first
  and after it a Blogit.Server worker process. When the Blogit.Server becomes
  active and loads all of the source repository data into itself, it creates
  the component specifications and adds them to the
  Blogit.Components.Supervisor process.

  This supervisor uses `one_for_one` strategy for its workers as they are
  not dependent on each other. They are dependent on the Blogit.Server
  process, so if it dies, this supervisor is restated and its child processes
  are added by the newly restarted Blogit.Server process.
  """

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: supervise([], [strategy: :one_for_one])
end
