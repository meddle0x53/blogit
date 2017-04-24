defmodule Blogit.Server do
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
  defstruct [
    :repository, :posts, :configuration, :repository_provider
  ]

  ##########
  # Client #
  ##########

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

  def handle_call(:get_configuration, _from, %{configuration: conf} = state) do
    {:reply, conf, state}
  end

  def handle_call(:get_posts, _from, %{posts: posts} = state) do
    {:reply, posts, state}
  end

  ###########
  # Private #
  ###########

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
      repository: repo, posts: posts, configuration: configuration,
      repository_provider: repository_provider
    }
  end

  defp try_check_after_interval(false, _), do: nil
  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end
end
