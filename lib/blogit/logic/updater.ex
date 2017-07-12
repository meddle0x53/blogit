defmodule Blogit.Logic.Updater do
  @moduledoc """
  Contains the function `check_updates/1` for checking for new updates using
  a `Blogit.RepositoryProvider`.

  Checking for updates should be done in a specific process, so the main
  posts repository is not blocked while checking for updates.
  """

  alias Blogit.Models.Post
  alias Blogit.Models.Post.Meta
  alias Blogit.Models.Configuration

  @type check_updates_result ::
    :no_updates |
    {:updates, %{
      posts: %{atom => Post.t}, configurations: [Configuration.t]
    }}

  @doc """
  Checks for new updates of the state in the remote/local repository.
  The state should contain a `Blogit.RepositoryProvider` structure
  and a repository.

  If there are no updates in the repository, the atom :no_updates is returned.

  If there are updates in the repository, a tuple of two elements is returned:
  {
    :updates,
    %{posts: <updated-posts-as-map>, configuration: <updated-configuration>}
  }.

  This function is called in a supervised Task by the `Blogit.Server` process.
  """
  @spec check_updates(Blogit.Server.t) :: check_updates_result
  def check_updates(state) do
    case state.repository.provider.fetch(state.repository.repo) do
      {:no_updates} -> :no_updates
      {:updates, updates} -> update(updates, state)
    end
  end

  defp update(updates, state) do
    posts = updated_posts(state.posts, updates, state.repository)
    posts = updated_posts_by_meta(posts, updates, state.repository)
    configurations = updated_blog_configuration(
      state.configurations,
      Configuration.updated?(updates),
      state.repository.provider
    )

    {:updates, %{posts: posts, configurations: configurations}}
  end

  defp updated_posts(current_posts, updates, repository) do
    new_files = Enum.filter(updates, &repository.provider.file_in?/1)
    deleted_posts = (updates -- new_files)
                    |> Post.names_from_files |> Enum.map(&String.to_atom/1)
    current_posts
    |> Map.merge(Post.compile_posts(new_files, repository))
    |> Map.drop(deleted_posts)
  end

  defp updated_posts_by_meta(current_posts, updates, repository) do
    files = updates |> Enum.filter(fn (f) ->
      String.starts_with?(f, Meta.folder) && String.ends_with?(f, ".yml")
    end) |> Enum.map(fn (f) ->
      f |> String.replace("meta/", "") |> String.replace_suffix("yml", "md")
    end)

    Map.merge(current_posts, Post.compile_posts(files, repository))
  end

  defp updated_blog_configuration(_, true, rp) do
    Configuration.from_file(rp)
  end

  defp updated_blog_configuration(current, false, _), do: current
end
