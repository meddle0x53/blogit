defmodule Blogit.Post do
  alias Blogit.GitRepository

  @enforce_keys [:name, :path, :raw, :html]
  @time_format "{YYYY}-{M}-{D} {h24}:{m}:{s} {Z}"
  @posts_folder Application.get_env(:blogit, :posts_folder, "/")

  defstruct [
    :name, :path, :raw, :html, :created_at, :updated_at, :author, :title
  ]

  def from_file_name(file_name, repository) do
    name = name_from_file(file_name)
    file = GitRepository.local_path
           |> Path.join(@posts_folder) |> Path.join(file_name)

    raw = File.read!(file)
    html = Earmark.to_html(String.replace(raw, ~r/^\s*\#\s*.+/, ""))

    created_at = GitRepository.file_created_at(repository, file_name)
    updated_at = GitRepository.file_updated_at(repository, file_name)

    %__MODULE__{
      name: name, path: file, raw: raw, html: html,
      updated_at: updated_at, created_at: created_at,
      author: GitRepository.file_author(repository, file_name),
      title: retrieve_title(raw, name)
    }
  end

  def compile_posts(list, repository) when is_list(list) do
    list
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> Enum.map(fn(file) ->
        from_file_name(file, repository)
      end)
    |> Enum.map(fn(post) -> {String.to_atom(post.name), post} end)
    |> Enum.into(%{})
  end

  def name_from_file(file_name) do
    file_name |> String.downcase |> String.trim_trailing(".md")
  end

  def names_from_files(files) do
    files
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> name_from_file
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
