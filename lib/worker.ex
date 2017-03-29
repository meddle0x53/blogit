defmodule Blogit.Worker do
  use GenServer

  alias Blogit.Post
  alias Blogit.Configuration
  alias Blogit.GitRepository
  alias Blogit.Search

  @polling Application.get_env(:blogit, :polling, true)
  @poll_interval Application.get_env(:blogit, :poll_interval, 10_000)

  ##########
  # Client #
  ##########

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  ##########
  # Server #
  ##########

  def init(_) do
    repository = GitRepository.updated_repository
    posts = Post.compile_posts(GitRepository.local_files, repository)
    blog = Configuration.from_file

    try_check_after_interval(@polling, @poll_interval)
    {:ok, %{
      repository: repository, posts: posts, blog: blog, posts_by_dates: nil}}
  end

  def handle_info(:check_updates, state) do
    Task.Supervisor.async_nolink(
      :tasks_supervisor, Blogit.Updater, :check_updates, [state]
    )
    {:noreply, state}
  end

  def handle_info({_, :no_updates}, state), do: {:noreply, state}

  def handle_info({_, {:updates, %{posts: posts, blog: blog}}}, state) do
    {:noreply, %{state | posts: posts, blog: blog, posts_by_dates: nil}}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    try_check_after_interval(@polling, @poll_interval)
    {:noreply, state}
  end

  def handle_call({:list_posts, from, size}, _from, state = %{posts: posts}) do
    result = Map.values(posts)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, state}
  end

  def handle_call(:list_pinned, _from, state = %{posts: posts}) do
    result = Map.values(posts)
             |> Enum.filter(fn post -> post.meta.pinned end)
             |> Post.sorted_updated
             |> Enum.map(fn post -> {post.name, post.meta.title} end)

    {:reply, result, state}
  end

  def handle_call(:posts_by_dates, _from, state = %{
    posts_by_dates: posts_by_dates, posts: posts
  }) do
    result = posts_by_dates ||
      Post.collect_by_year_and_month(Map.values(posts))
    {:reply, result, %{state | posts_by_dates: posts_by_dates}}
  end

  def handle_call(
    {:filter_posts, filters, from, size}, _from, state = %{posts: posts}
  ) do
    result = Map.values(posts) |> Search.filter_by_params(filters)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, state}
  end

  def handle_call({:post_by_name, name}, _from, state = %{posts: posts}) do
    case post = posts[name] do
      nil -> {:reply, :error, state}
      _ -> {:reply, post, state}
    end
  end

  def handle_call(:blog_configuration, _from, state = %{blog: blog}) do
    {:reply, blog, state}
  end

  ###########
  # Private #
  ###########

  defp try_check_after_interval(false, _), do: nil
  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end
end
