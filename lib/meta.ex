defmodule Blogit.Meta do
  alias Blogit.GitRepository

  @posts_folder Application.get_env(:blogit, :posts_folder, "")
  @meta_divider Application.get_env(:blogit, :meta_divider, "<><><><><><><><>")

  defstruct [
    :created_at, :updated_at, :author, :title, :category, :tags, :published,
    :title_image_path
  ]

  def from_file_name(file_name, repository, raw, name) do
    meta_file_name = file_name |> String.replace_suffix(".md", ".yml")
    meta_path = GitRepository.local_path
                |> Path.join(@posts_folder)
                |> Path.join("meta")
                |> Path.join(meta_file_name)

    create_meta(File.read(meta_path), file_name, repository, raw, name)
  end

  def folder, do: Path.join(@posts_folder, "meta") |> String.trim_leading("/")

  defp create_meta({:error, _}, file_name, repository, raw, name) do
    create_from_map(
      merge_with_inline(%{}, raw), file_name, repository, raw, name
    )
  end

  defp create_meta({:ok, data}, file_name, repository, raw, name) do
    meta = merge_with_inline(YamlElixir.read_from_string(data), raw)
    create_from_map(meta, file_name, repository, raw, name)
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

    merge_meta(data, YamlElixir.read_from_string(raw_meta))
  end

  defp merge_meta(current, inline) when is_map(inline) do
    Map.merge(current, inline)
  end

  defp merge_meta(current, _), do: current

  defp create_from_map(
    data, file_name, repository, raw, name
  ) when is_map(data) do
    %__MODULE__{
      created_at: data["created_at"] ||
        GitRepository.file_created_at(repository, file_name),
      updated_at: data["updated_at"] ||
        GitRepository.file_updated_at(repository, file_name),
      author: data["author"] ||
        GitRepository.file_author(repository, file_name),
      title: data["title"] || retrieve_title(raw, name),
      tags: Map.get(data, "tags", []) |> Enum.map(&Kernel.to_string/1),
      published: Map.get(data, "published", true),
      category: data["category"],
      title_image_path: data["title_image_path"]
    }
  end

  defp create_from_map(_, file_name, repository, raw, name) do
    create_from_map(%{}, file_name, repository, raw, name)
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
