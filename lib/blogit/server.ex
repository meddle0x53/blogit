defmodule Blogit.Server do
  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.Components.Posts
  alias Blogit.Components.PostsByDate

  alias Blogit.RepositoryProvider, as: Repository

  @polling Application.get_env(:blogit, :polling, true)
  @poll_interval Application.get_env(:blogit, :poll_interval, 10_000)

  @enforce_keys [
    :repository, :posts, :configuration, :sup, :repository_provider
  ]
  defstruct [
    :repository, :posts, :configuration, :sup,
    :repository_provider, :components_sup
  ]

  ##########
  # Client #
  ##########

  def start_link(sup, repository_provider) do
    GenServer.start_link(
      __MODULE__, [sup, repository_provider], name: __MODULE__
    )
  end

  ##########
  # Server #
  ##########

  def init([sup, repository_provider])
  when is_pid(sup) and is_atom(repository_provider) do
    state = init_state(sup, repository_provider)

    send(self(), :setup_components)

    {:ok, state}
  end

  def handle_info(:setup_components, %{sup: sup} = state) do
    {:ok, components_sup} = Supervisor.start_child(sup, supervisor_spec())

    try_check_after_interval(@polling, @poll_interval)

    {:noreply, %{state | components_sup: components_sup}}
  end

  def handle_info(:check_updates, state) do
    Task.Supervisor.async_nolink(
      :tasks_supervisor, Blogit.Updater, :check_updates, [state]
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

  defp supervisor_spec() do
    import Supervisor.Spec, warn: false

    supervisor(Blogit.Components.Supervisor, [], restart: :temporary)
  end

  defp init_state(sup, repository_provider) do
    repo = repository_provider.updated_repository
    repository = %Repository{repo: repo, provider: repository_provider}

    posts = Post.compile_posts(repository_provider.local_files, repository)
    configuration = Configuration.from_file(repository_provider)

    %__MODULE__{
      repository: repo, posts: posts, configuration: configuration,
      repository_provider: repository_provider, sup: sup
    }
  end

  defp try_check_after_interval(false, _), do: nil
  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end
end
