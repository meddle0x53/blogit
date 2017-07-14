defmodule Blogit.RepositoryProviders.Git do
  @moduledoc """
  This module implements the `Blogit.RepositoryProvider` behaviour.

  It provides access to a git repository which could contain posts as markdown
  files and blog configuration and styles.

  If the git repository is not accessible in the moment the locally checked one
  will be used and won't be updated.

  The URL to the git repository have to be specified using the :blogit setting
  :repository_url in the configuration.

  The main folder containing the posts could be specified with the :posts_folder
  setting. By default it is the root of the git repository.

  For author of a post markdown file
  (if not specified manually in the meta data) is used the creator of the file
  in the git repository. For creation date is used the date of the first
  commit of the file and for the last update date is used the date of the last
  commit of the file.

  The `Blogit.RepositoryProvider.updated_repository/0` implementation does
  `git pull` before returning the repository representation. The
  `Blogit.RepositoryProvider.fetch/1` implementation uses `git fetch` to check
  for deleted, added or updated files.
  """

  require Logger

  @behaviour Blogit.RepositoryProvider

  @repository_url Application.get_env(:blogit, :repository_url)
  @local_path @repository_url
              |> String.split("/")
              |> List.last
              |> String.trim_trailing(".git")

  #############
  # Behaviour #
  #############

  def repository do
    case Git.clone(@repository_url) do
      {:ok, repo} -> repo
      {:error, %Git.Error{code: 128}} -> Git.new(@local_path)
    end
  end

  def updated_repository do
    repo = repository()
    case Git.pull(repo) do
      {:ok, msg} -> Logger.info("Pulling from git repository #{msg}")
      {_, error} ->
        Logger.error(
          "Error while pulling from git repository #{inspect(error)}"
        )
    end

    repo
  end

  def fetch(repo) do
    case Git.fetch(repo) do
      {:error, _} -> {:no_updates}
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

  def local_files do
    path = Path.join(@local_path, Blogit.Settings.posts_folder())
    size = byte_size(path) + 1

    recursive_ls(path)
    |> Enum.map(fn << _::binary-size(size), rest::binary >> -> rest end)
  end

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

  def read_file!(file_path, folder \\ "") do
    file = local_path()
           |> Path.join(folder) |> Path.join(file_path)

    File.read!(file)
  end

  def read_file(file_path, folder \\ "") do
    local_path() |> Path.join(folder) |> Path.join(file_path) |> File.read
  end

  def read_meta_file(file_path, folder \\ "") do
    meta_file_path = file_path |> String.replace_suffix(".md", ".yml")
    meta_path = local_path()
                |> Path.join(folder)
                |> Path.join("meta")
                |> Path.join(meta_file_path)

    File.read(meta_path)
  end

  ###########
  # Private #
  ###########

  defp log(repository, args), do: Git.log!(repository, args)

  defp first_in_log(repository, args) do
    log(repository, args) |> String.split("\n") |> List.first |> String.trim
  end

  defp recursive_ls(path) do
    cond do
      File.regular?(path) -> [path]
      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&recursive_ls/1)
        |> Enum.concat
      true -> []
    end
  end
end
