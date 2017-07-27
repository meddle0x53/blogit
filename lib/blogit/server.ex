defmodule Blogit.Server do
  @moduledoc """
  This module represents the core process of Blogit.

  This process is responsible for loading the blog data from a repository,
  using specified `Blogit.RepositoryProvider` implementation and keeping it
  converted into structures. The component processes use these structures
  as their state.

  If `polling` is configured to true, this process polls for changes in the
  source repository on interval, configured with `poll_interval`. By default
  this interval is 10 seconds.

  This process is started and supervised as worker by `Blogit.Supervisor`.
  It uses Task processes to check for updated, which are supervised by the
  Task.Supervisor process, started and supervised by `Blogit.Supervisor`.

  If there are changes in the source repository, it is this process'
  responsibility to update the component processes.

  The component processes are added as workers by this process to the
  `Blogit.Components.Supervisor`, which starts with no workers. This is so,
  because they are dependent on the `Blogit.Server` process and it must be
  started and ready to accept messages before them.
  """

  use GenServer

  alias Blogit.Settings

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.Components.Posts
  alias Blogit.Components.Metas
  alias Blogit.Components.PostsByDate
  alias Blogit.Components.Supervisor, as: ComponentsSupervisor

  alias Blogit.RepositoryProvider, as: Repository

  @polling Application.get_env(:blogit, :polling, true)
  @poll_interval Application.get_env(:blogit, :poll_interval, 10_000)

  @enforce_keys [:repository, :posts, :configurations]
  @type t :: %__MODULE__{
    repository: Repository.t, posts: %{atom => Post.t},
    configurations: [Configuration.t]
  }
  defstruct [:repository, :posts, :configurations]

  ##########
  # Client #
  ##########

  @doc """
  Starts the `Blogit.Server` process.

  This function has one argument - a module which must implement the
  `Blogit.RepositoryProvider` behaviour. It is used to read data from the
  source repository and to check for updates.

  Once the process starts, it reads all the data from the repository, using
  the given provider, converts it to Blogit.Models structures and creates
  the component processes.

  Every component process should retrieve the data it needs from the
  `Blogit.Server` process. When there are updates, the blogit server will
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
    setup_components()

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
    {_, {:updates, %{posts: posts, configurations: configurations}}}, state
  ) do
    configurations |> Enum.each(fn configuration ->
      name = Blogit.Components.Configuration.name(configuration.language)
      GenServer.cast(name, {:update, configuration})
      GenServer.cast(
        Posts.name(configuration.language),
        {:update, posts[configuration.language]}
      )
      GenServer.cast(PostsByDate.name(configuration.language), :reset)
    end)

    {:noreply, %{state | posts: posts, configurations: configurations}}
  end

  def handle_info({:DOWN, _, :process, _, _}, state) do
    try_check_after_interval(@polling, @poll_interval)
    {:noreply, state}
  end

  def handle_call(
    {:get_configuration, language}, {pid, _}, %{configurations: conf} = st
  ) do
    configuration = conf |> Enum.find(&(&1.language == language))
    names = conf
            |> Enum.map(&(Blogit.Components.Configuration.name(&1.language)))
    ensure_caller(pid, names, configuration, st)
  end

  def handle_call({:get_posts, language}, {pid, _}, %{posts: posts} = state) do
    names = Settings.languages() |> Enum.map(&(Posts.name(&1)))
    ensure_caller(pid, names, posts[language], state)
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

  defp supervisor_spec({module, name}) do
    import Supervisor.Spec, warn: false

    worker(module, [name], id: module.name(name))
  end

  defp init_state(repository_provider) do
    repo = repository_provider.repository()
    repository = %Repository{repo: repo, provider: repository_provider}

    posts = Post.compile_posts(repository_provider.list_files(), repository)
    configurations = Configuration.from_file(repository_provider)

    %__MODULE__{
      repository: repository, posts: posts, configurations: configurations
    }
  end

  defp try_check_after_interval(false, _), do: nil
  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end

  defp setup_components do
    languages = Settings.languages()
    components = languages |> Enum.reduce([], fn language, current ->
      module = Blogit.Components.Configuration
      [
        {module, language},
        {Posts, language},
        {PostsByDate, language},
        {Metas, language}
        | current
      ]
    end)

    components |> Enum.each(fn (component) ->
      {:ok, _} =
        Supervisor.start_child(ComponentsSupervisor, supervisor_spec(component))
    end)
  end
end
