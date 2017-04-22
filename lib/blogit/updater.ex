defmodule Blogit.Updater do
  alias Blogit.Models.Post
  alias Blogit.Models.Post.Meta
  alias Blogit.Models.Configuration

  alias Blogit.RepositoryProvider, as: Repository

  def check_updates(state) do
    rp = state.repository_provider
    repository = state.repository

    case rp.fetch(repository) do
      {:no_updates} -> :no_updates
      {:updates, updates} -> update(updates, state, rp, repository)
    end
  end

  defp update(updates, state, rp, repository) do
    posts = updated_posts(state.posts, updates, rp, repository)
    posts = updated_posts_by_meta(posts, updates, rp, repository)
    blog = updated_blog_configuration(
      state.configuration, Configuration.updated?(updates), rp
    )

    {:updates, %{posts: posts, configuration: blog}}
  end

  defp updated_posts(current_posts, updates, rp, repository) do
    new_files = Enum.filter(updates, &rp.file_in?/1)
    deleted_posts = (updates -- new_files)
                    |> Post.names_from_files |> Enum.map(&String.to_atom/1)
    current_posts
    |> Map.merge(Post.compile_posts(new_files, %Repository{repo: repository, provider: rp}))
    |> Map.drop(deleted_posts)
  end

  defp updated_posts_by_meta(current_posts, updates, rp, repository) do
    files = updates |> Enum.filter(fn (f) ->
      String.starts_with?(f, Meta.folder) && String.ends_with?(f, ".yml")
    end) |> Enum.map(fn (f) ->
      f |> String.replace("meta/", "") |> String.replace_suffix("yml", "md")
    end)

    Map.merge(current_posts, Post.compile_posts(files, %Repository{repo: repository, provider: rp}))
  end

  defp updated_blog_configuration(_, true, rp), do: Configuration.from_file(rp)
  defp updated_blog_configuration(current, false, _), do: current
end
