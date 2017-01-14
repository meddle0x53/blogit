defmodule Blogit.Worker do
  use GenServer

  alias Blogit.Post
  alias Blogit.GitRepository

  @polling Application.get_env(:blogit, :polling)
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

    if @polling, do: check_after_interval(@poll_interval)
    {:ok, %{repository: repository, posts: posts}}
  end

  def handle_info(:check_updates, state) do
    repository = state[:repository]
    case GitRepository.fetch(repository) do
      {:no_updates} ->
        if @polling, do: check_after_interval(@poll_interval)
        {:noreply, state}
      {:updates, updates} ->
        posts = updated_posts(state[:posts], updates, repository)

        if @polling, do: check_after_interval(@poll_interval)
        {:noreply, %{state | posts: posts}}
    end
  end

  def handle_call(:list_posts, _from, state = %{posts: posts}) do
    {:reply, Map.values(posts), state}
  end

  def handle_call({:post_by_name, name}, _from, state = %{posts: posts}) do
    case post = posts[name] do
      nil -> {:reply, :error, state}
      _ -> {:reply, post, state}
    end
  end

  ###########
  # Private #
  ###########

  defp check_after_interval(interval) do
    Process.send_after(self, :check_updates, interval)
  end

  defp updated_posts(current_posts, updates, repository) do
    new_files = Enum.filter(updates, &GitRepository.file_in?/1)
    deleted_posts = (updates -- new_files)
                    |> Post.names_from_files |> Enum.map(&String.to_atom/1)
    current_posts
    |> Map.merge(Post.compile_posts(new_files, repository))
    |> Map.drop(deleted_posts)
  end
end
