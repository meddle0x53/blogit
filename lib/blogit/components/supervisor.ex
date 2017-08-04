defmodule Blogit.Components.Supervisor do
  @moduledoc """
  Represents a `Supervisor`, which supervises the components worker
  processes.

  By default this Supervisor starts with no children.
  `Blogit.Supervisor` starts a supervisor process implementing this module first
  and after it a `Blogit.Server` worker process. When the `Blogit.Server` becomes
  active and loads all of the source repository data into itself, it creates
  the component specifications and adds them to the
  `Blogit.Components.Supervisor` process.

  This supervisor uses `one_for_one` strategy for its workers as they are
  not dependent on each other. They are dependent on the `Blogit.Server`
  process, so if it dies, this supervisor is restated and its child processes
  are added by the newly restarted `Blogit.Server` process.

  Every type of component will have a process for every language configured
  for `Blogit` with its unique id. For example if `Blogit` is configured to
  support `bg` and `en`, the `Blogit.Components.Posts` module will have two
  worker processes, one with id `posts_bg` and one with `posts_en`. Every
  language configured has its own set of data and processes, which are isolated
  from the data and the processes of the other languages.
  """

  use Supervisor

  @doc """
  Starts the `Blogit.Components.Supervisor` process.

  The strategy of the `Blogit.Components.Supervisor` is `one_for_one` and it
  starts with no children specifications. The specifications of the components
  are added to it by the `Blogit.Server` worker process once it can accept
  messages and has the data needed by the component processes as its state.

  ## Examples

      iex> {:ok, pid} = Blogit.Components.Supervisor.start_link()
      iex> is_pid(pid)
      true

      iex> {:ok, pid} = Blogit.Components.Supervisor.start_link()
      iex> Process.alive?(pid)
      true

      iex> {:ok, pid} = Blogit.Components.Supervisor.start_link()
      iex> Supervisor.count_children(pid)
      %{active: 0, specs: 0, supervisors: 0, workers: 0}

      iex> {:ok, pid} = Blogit.Components.Supervisor.start_link()
      iex> elem(:sys.get_state(pid), 2) # strategy
      :one_for_one
  """
  @spec start_link() :: Supervisor.on_start
  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: supervise([], [strategy: :one_for_one])
end
