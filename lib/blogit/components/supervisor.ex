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

  @doc """
  Starts the Supervisor.

  The strategy of the Blogit.Components.Supervisor is `one_for_one` and it
  starts with no children specifications. The specifications of the components
  are added to it by the Blogit.Server worker process once it can accept
  messages and has the data needed by the component processes loaded.
  """
  @spec start_link() :: Supervisor.on_start
  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: supervise([], [strategy: :one_for_one])
end
