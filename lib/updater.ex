defmodule Blogit.Updater do
  alias Blogit.Post
  alias Blogit.Meta
  alias Blogit.Configuration
  alias Blogit.GitRepository

  def check_updates(state) do
    repository = state[:repository]
    case GitRepository.fetch(repository) do
      {:no_updates} -> :no_updates
      {:updates, updates} -> update(updates, state, repository)
    end
  end

  defp update(updates, state, repository) do
    posts = updated_posts(state[:posts], updates, repository)
    posts = updated_posts_by_meta(posts, updates, repository)
    blog =
      updated_blog_configuration(state[:blog], Configuration.updated?(updates))

    {:updates, %{posts: posts, blog: blog}}
  end

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
      String.starts_with?(f, Meta.folder) && String.ends_with?(f, ".yml")
    end) |> Enum.map(fn (f) ->
      f |> String.replace("meta/", "") |> String.replace_suffix("yml", "md")
    end)

    Map.merge(current_posts, Post.compile_posts(files, repository))
  end

  defp updated_blog_configuration(_, true), do: Configuration.from_file
  defp updated_blog_configuration(current, false), do: current
end
