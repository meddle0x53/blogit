defmodule Blogit.Worker do
  use GenServer

  alias Blogit.Post

  @repository_url Application.get_env(:blogit, :repository_url)
  @polling Application.get_env(:blogit, :polling)
  @poll_interval Application.get_env(:blogit, :poll_interval, 10_000)
  @local_path @repository_url
              |> String.split("/")
              |> List.last
              |> String.trim_trailing(".git")

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
    repository =
      case Git.clone(@repository_url) do
        {:ok, repo} -> repo
        {:error, %Git.Error{code: 128}} -> Git.new(@local_path)
      end

    Git.pull!(repository)
    posts = compile_posts(File.ls!(@local_path), repository)

    if @polling, do: check_after_interval(@poll_interval)
    {:ok, %{repository: repository, posts: posts}}
  end

  def handle_info(:check_updates, state) do
    repository = state[:repository]
    case Git.fetch(repository) do
      {:ok, ""} ->
        IO.puts "No updates."
        if @polling, do: check_after_interval(@poll_interval)
        {:noreply, state}
      {:ok, _} ->
        updates =
          Git.diff!(repository, ["--name-only", "HEAD", "origin/master"])
          |> String.split("\n", trim: true)

        Git.pull!(repository)
        new_files = Enum.filter(
          updates, fn(u) -> File.exists?(Path.join(@local_path, u)) end
        )
        deleted_posts = (updates -- new_files)
                        |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
                        |> Enum.map(&String.downcase/1)
                        |> Enum.map(&(String.trim_trailing(&1, ".md")))
                        |> Enum.map(&String.to_atom/1)

        posts = state[:posts]
                |> Map.merge(compile_posts(new_files, repository))
                |> Map.drop(deleted_posts)
        IO.puts inspect posts
        IO.puts inspect %{state | posts: posts}
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

  defp compile_posts(list, repository) when is_list(list) do
    IO.puts list

    list
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> Enum.map(fn(file) ->
        Post.from_file_name(file, @local_path, repository)
      end)
    |> Enum.map(fn(post) -> {String.to_atom(post.name), post} end)
    |> Enum.into(%{})
  end
end

