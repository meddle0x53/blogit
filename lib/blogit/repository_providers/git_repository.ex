defmodule Blogit.RepositoryProviders.Git do
  @behaviour Blogit.RepositoryProvider

  @repository_url Application.get_env(:blogit, :repository_url)
  @local_path @repository_url
              |> String.split("/")
              |> List.last
              |> String.trim_trailing(".git")
  @posts_folder Application.get_env(:blogit, :posts_folder, ".")

  def repository do
    case Git.clone(@repository_url) do
      {:ok, repo} -> repo
      {:error, %Git.Error{code: 128}} -> Git.new(@local_path)
    end
  end

  def updated_repository do
    repo = repository()
    Git.pull!(repo)

    repo
  end

  def fetch(repo) do
    case Git.fetch(repo) do
      {:ok, ""} -> {:no_updates}
      {:ok, _} ->
        updates =
          Git.diff!(repo, ["--name-only", "HEAD", "origin/master"])
          |> String.split("\n", trim: true) |> Enum.map(&String.trim/1)
        Git.pull!(repo)

        {:updates, updates}
    end
  end

  def local_path, do: @local_path
  def local_files, do: File.ls!(Path.join(@local_path, @posts_folder))
  def file_in?(file), do: File.exists?(Path.join(@local_path, file))

  def file_author(repository, file_name) do
    first_in_log(repository, ["--reverse", "--format=%an", file_name])
  end

  def file_created_at(repository, file_name) do
    first_in_log(repository, ["--reverse", "--format=%ci", file_name])
  end

  def file_updated_at(repository, file_name) do
    log(repository, ["-1", "--format=%ci", file_name]) |> String.trim
  end

  defp log(repository, args), do: Git.log!(repository, args)

  defp first_in_log(repository, args) do
    log(repository, args) |> String.split("\n") |> List.first |> String.trim
  end
end
