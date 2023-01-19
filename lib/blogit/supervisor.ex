defmodule Blogit.Supervisor do
  @moduledoc """
  This module represents the root Supervisor of Blogit.

  It uses a `one_for_all` strategy to supervise its children.
  The children are:
  * `Blogit.Server` worker used as the core process of `Blogit`. If it fails
    all the top-level processes of the application must be restarted, thus
    the `one_for_all` strategy.
  * `Blogit.Components.Supervisor` supervisor which supervises
    the components of Blogit that can be queried. If this process fails it will
    be good to restart all the top-level processes, because the `Blogit.Server`
    process is used by the components to manage their data.
  * A Task.Supervisor used to supervise all the Tasks in Blogit.
  * If the Applications is using the `Blogit.RepositoryProviders.Memory`
    provider, a worker representing the in-memory repository is started
    and supervised too.

  `Blogit.Supervisor` is started in `Blogit.start/2` using
  `Blogit.Supervisor.start_link/1` and the result of this call is what the
  `start` function of the `Blogit` application returns.
  """

  use Supervisor

  @doc """
  Accepts a module implementing `Blogit.RepositoryProvider` and starts the
  supervisor defined by this module.

  The `Blogit.RepositoryProvider` module is passed to the `Supervisor.init/1`
  callback implemented by this module and is used to create and start the
  `Blogit.Server` worker.

  This function is called by `Blogit.start/2` and its result is returned by it.
  """
  @spec start_link(module) :: Supervisor.on_start()
  def start_link(repository_provider) do
    Supervisor.start_link(__MODULE__, repository_provider, name: __MODULE__)
  end

  @impl true
  def init(repository_provider) do
    children = [
      {Blogit.Components.Supervisor, []},
      {Task.Supervisor, name: :tasks_supervisor},
      {Blogit.Server, repository_provider}
    ]

    children =
      case repository_provider do
        Blogit.RepositoryProviders.Memory ->
          [{repository_provider, []} | children]

        _ ->
          children
      end

    Supervisor.init(children, strategy: :one_for_all)
  end
end
