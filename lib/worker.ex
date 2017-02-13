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
    repository = state[:repository]
    case GitRepository.fetch(repository) do
      {:no_updates} ->
        try_check_after_interval(@polling, @poll_interval)
        {:noreply, state}
      {:updates, updates} ->
        posts = updated_posts(state[:posts], updates, repository)
        posts = updated_posts_by_meta(posts, updates, repository)
        blog = updated_blog_configuration(
          state[:blog], Configuration.updated?(updates)
        )

        try_check_after_interval(@polling, @poll_interval)
        {:noreply, %{
          state | posts: posts, blog: blog, posts_by_dates: nil}}
    end
  end

  def handle_call(:list_posts, _from, state = %{posts: posts}) do
    result = Map.values(posts) |> Post.sorted

    {:reply, result, state}
  end

  def handle_call(:posts_by_dates, _from, state = %{
    posts_by_dates: posts_by_dates, posts: posts
  }) do
    result = posts_by_dates ||
      Post.collect_by_year_and_month(Map.values(posts) |> Post.reverse)
    {:reply, result, %{state | posts_by_dates: posts_by_dates}}
  end

  def handle_call({:filter_posts, filters}, _from, state = %{posts: posts}) do
    result = Map.values(posts) |> Search.filter_by_params(filters)

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

  defp try_check_after_interval(true, interval) do
    Process.send_after(self(), :check_updates, interval)
  end

  defp try_check_after_interval(false, _), do: nil

  defp updated_blog_configuration(_, true), do: Configuration.from_file
  defp updated_blog_configuration(current, false), do: current

  defp updated_posts(current_posts, updates, repository) do
    new_files = Enum.filter(updates, &GitRepository.file_in?/1)
    deleted_posts = (updates -- new_files)
                    |> Post.names_from_files |> Enum.map(&String.to_atom/1)
    current_posts
    |> Map.merge(Post.compile_posts(new_files, repository))
    |> Map.drop(deleted_posts)
  end

  defp updated_posts_by_meta(current_posts, updates, repository) do
    files = updates |> Enum.filter(fn (f) ->
      String.starts_with?(f, Blogit.Meta.folder) && String.ends_with?(f, ".yml")
    end) |> Enum.map(fn (f) ->
      f |> String.replace("meta/", "") |> String.replace_suffix("yml", "md")
    end)

    Map.merge(current_posts, Post.compile_posts(files, repository))
  end
end
