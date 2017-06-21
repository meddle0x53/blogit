defmodule Blogit.Server do
  @moduledoc """
  This module represents the core process of Blogit.

  This process is responsible for loading the blog data from a repository,
  using specified Blogit.RepositoryProvider implementation and keeping it
  converted into structures. The component processes use these structures
  as their state.

  If `polling` is configured to true, this process polls for changes in the
  source repository on interval, configured with `poll_interval`. By default
  this inteval is 10 seconds.

  This process is started and supervised as worker by Blogit.Supervisor.
  It uses Task processes to chake for updated, which are supervised by the
  Task.Supervisor process, started and supervised by Blogit.Supervisor.

  If there are changes in the source repository, it is this process'
  reposnibility to update the component processes.

  The component processes are added as workers by this process to the
  Blogit.Components.Supervisor, which starts with no workers. This is so,
  because they are dependent on the Blogit.Server process and it must be
  started and ready to accept messages before them.
  """

  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.Components.Posts
  alias Blogit.Components.PostsByDate

  alias Blogit.RepositoryProvider, as: Repository
  alias Blogit.Components.Supervisor, as: ComponentsSupervisor

  @polling Application.get_env(:blogit, :polling, true)
  @poll_interval Application.get_env(:blogit, :poll_interval, 10_000)

  @enforce_keys [
    :repository, :posts, :configuration, :repository_provider
  ]
  @type t :: %__MODULE__{
    repository: Repository.t, posts: %{atom => Post.t},
    configuration: Configuration.t, repository_provider: module
  }
  defstruct [
    :repository, :posts, :configuration, :repository_provider
  ]

  ##########
  # Client #
  ##########

  @doc """
  Starts the Blogit.Server process.

  This function has one argument - a module which must implement the
  Blogit.RepositoryProvider behaviour. It is used to read data from the
  source repository and to check for updates.

  Once the process starts, it reads all the data from the repository, using
  the given provider, converts it to Blogit.Models structures and creates
  the component processes.

  Every component process should retrieve the data it needs from the
  Blogit.Server process. When there are updates, the blogit server will
  update its components.
  """
  @spec start_link(module) :: GenServer.on_start
  def start_link(repository_provider) do
    GenServer.start_link(
      __MODULE__, repository_provider, name: __MODULE__
    )
  end

  ##########
  # Server #
  ##########

  def init(repository_provider) when is_atom(repository_provider) do
    state = init_state(repository_provider)

    send(self(), :setup_components)

    {:ok, state}
  end

  def handle_info(:setup_components, state) do
    [Posts, Blogit.Components.Configuration, PostsByDate]
    |> Enum.each(fn (module) ->
      {:ok, _} =
        Supervisor.start_child(ComponentsSupervisor, supervisor_spec(module))
    end)

    try_check_after_interval(@polling, @poll_interval)

    {:noreply, state}
  end

  def handle_info(:check_updates, state) do
    Task.Supervisor.async_nolink(
      :tasks_supervisor, Blogit.Logic.Updater, :check_updates, [state]
    )
    {:noreply, state}
  end

  def handle_info({_, :no_updates}, state), do: {:noreply, state}

  def handle_info(
    {_, {:updates, %{posts: posts, configuration: configuration}}}, state
  ) do
    GenServer.cast(Posts, {:update, posts})
    GenServer.cast(Blogit.Components.Configuration, {:update, configuration})
    GenServer.cast(PostsByDate, :stop)

    {:noreply, %{state | posts: posts, configuration: configuration}}
  end

  def handle_info({:DOWN, _, :process, _, _}, state) do
    try_check_after_interval(@polling, @poll_interval)
    {:noreply, state}
  end

  def handle_call(:get_configuration, {pid, _}, %{configuration: conf} = st) do
    ensure_caller(pid, [Blogit.Components.Configuration], conf, st)
  end

  def handle_call(:get_posts, {pid, _}, %{posts: posts} = state) do
    ensure_caller(pid, [Posts, PostsByDate], posts, state)
  end

  ###########
  # Private #
  ###########

  defp ensure_caller(pid, accepted_modules, reply, state) do
    possible_pids = accepted_modules |> Enum.map(&Process.whereis/1)
    if Enum.member?(possible_pids, pid) do
      {:reply, reply, state}
    else
      possible_pids =
        possible_pids |> Enum.map(&Kernel.inspect/1) |> Enum.join(" or ")
      {
        :stop,
        "This callback can only be invoked by " <>
        "#{possible_pids} but was invoked by #{inspect pid}",
        state
      }
    end
  end

  defp supervisor_spec(module) do
    import Supervisor.Spec, warn: false

    worker(module, [])
  end

  defp init_state(repository_provider) do
    repo = repository_provider.updated_repository
    repository = %Repository{repo: repo, provider: repository_provider}

    posts = Post.compile_posts(repository_provider.local_files, repository)
    configuration = Configuration.from_file(repository_provider)

    %__MODULE__{
      repository: repository, posts: posts, configuration: configuration,
      repository_provider: repository_provider
    }
  end

  defp try_check_after_interval(false, _), do: nil
  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end
end
