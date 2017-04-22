defmodule Blogit.Models.Post.Meta do
  @moduledoc """
  Represents the meta-data of a post.

  Provides function to read/parse the meta information from a file.
  All the meta-fields have default values.
  The meta information can be defined in different places.

  The highest priority place is the post itself. There is a configuration
  for `meta_divider` and the meta information can be stored at the top of the
  markdown file's content in YAML format. The markdown content and meta-data
  are divided using the `meta_divider`.

  With lower priority are files stored in a sub folder of the folder containing
  the post markdown files, called `meta/`. If a post content is sotred in a file
  called `some_post.md`, its meta-data have to be stored in a YAML file,
  located at `meta/some_post.yml`.

  With the lowest priority are the defaults and values read from the repository
  containing the file.
  """

  alias Blogit.RepositoryProvider, as: Repository

  @posts_folder Application.get_env(:blogit, :posts_folder, ".")
  @meta_divider Application.get_env(:blogit, :meta_divider, "<><><><><><><><>")

  @type t :: %__MODULE__{
    author: String.t, title: String.t, category: String.t, published: boolean,
    tags: [String.t], title_image_path: String.t, pinned: boolean,
    created_at: Calendar::NaiveDateTime.t,
    updated_at: Calendar::NaiveDateTime.t
  }
  defstruct [
    :created_at, :updated_at, :author, :title, :category, :tags, :published,
    :title_image_path, :pinned
  ]

  @doc """
  Creates a Post.Meta structure using the source file of a Post, its raw data
  and the repository containing the blog data.
  """
  @spec from_file(String.t, Repository.t, String.t, String.t) :: t
  def from_file(file_name, repository, raw, name) do
    meta_file_name = file_name |> String.replace_suffix(".md", ".yml")
    meta_path = repository.provider.local_path
                |> Path.join(@posts_folder)
                |> Path.join("meta")
                |> Path.join(meta_file_name)

    create_meta(
      File.read(meta_path),
      repository.provider, file_name, repository.repo, raw, name
    )
  end

  def folder, do: Path.join(@posts_folder, "meta") |> String.trim_leading("/")

  ###########
  # Private #
  ###########

  defp create_meta({:error, _}, rp, file_name, repository, raw, name) do
    create_from_map(
      merge_with_inline(%{}, raw), rp, file_name, repository, raw, name
    )
  end

  defp create_meta({:ok, data}, rp, file_name, repository, raw, name) do
    meta = merge_with_inline(YamlElixir.read_from_string(data), raw)
    create_from_map(meta, rp, file_name, repository, raw, name)
  end

  defp merge_with_inline(data, raw) when is_map(data) do
    merge_with_inline(data, raw, String.contains?(raw, @meta_divider))
  end

  defp merge_with_inline(_, raw) do
    merge_with_inline(%{}, raw, String.contains?(raw, @meta_divider))
  end

  defp merge_with_inline(data, _, false), do: data

  defp merge_with_inline(data, raw, true) do
    [raw_meta | _] = String.split(raw, @meta_divider, trim: true)
                     |> Enum.map(&String.trim/1)

    merge_meta(data, YamlElixir.read_from_string(raw_meta))
  end

  defp merge_meta(current, inline) when is_map(inline) do
    Map.merge(current, inline)
  end

  defp merge_meta(current, _), do: current

  defp create_from_map(data, rp, file_name, repository, raw, name)
  when is_map(data) do
    created_at = data["created_at"] || rp.file_created_at(
      repository, Path.join(@posts_folder, file_name)
    )
    updated_at = data["updated_at"] || rp.file_updated_at(
      repository, Path.join(@posts_folder, file_name)
    )
    author = data["author"] || rp.file_author(
      repository, Path.join(@posts_folder, file_name)
    )
    {:ok, created_at, _} = Calendar.NaiveDateTime.Parse.iso8601(created_at)
    {:ok, updated_at, _} = Calendar.NaiveDateTime.Parse.iso8601(updated_at)

    %__MODULE__{
      created_at: created_at, updated_at: updated_at, author: author,
      title: data["title"] || retrieve_title(raw, name),
      tags: Map.get(data, "tags", []) |> Enum.map(&Kernel.to_string/1),
      published: Map.get(data, "published", true),
      category: data["category"],
      title_image_path: data["title_image_path"],
      pinned: data["pinned"] || false
    }
  end

  defp create_from_map(_, rp, file_name, repository, raw, name) do
    create_from_map(%{}, rp, file_name, repository, raw, name)
  end

  defp retrieve_title(raw, name) do
    guess_title(Regex.named_captures(~r/^\s*\#\s*(?<title>.+)$/m, raw), name)
  end

  defp guess_title(%{"title" => title}, _), do: title
  defp guess_title(_, name) do
    name
    |> String.split(~r{[^A-Za-z0-9]}) |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
