defmodule Blogit.Post do
  use Timex

  alias Blogit.GitRepository

  @enforce_keys [:name, :path, :raw, :html]
  @time_format "{YYYY}-{M}-{D} {h24}:{m}:{s} {Z}"

  defstruct [:name, :path, :raw, :html, :created_at, :updated_at, :author]

  def from_file_name(file_name, repository) do
    name = name_from_file(file_name)
    file = Path.join(GitRepository.local_path, file_name)
    raw = File.read!(file)
    html = Earmark.to_html(raw)

    created_at =
      time_from_string(GitRepository.file_created_at(repository, file_name))
    updated_at =
      time_from_string(GitRepository.file_updated_at(repository, file_name))

    %__MODULE__{
      name: name, path: file, raw: raw, html: html,
      updated_at: updated_at, created_at: created_at,
      author: GitRepository.file_author(repository, file_name)
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

  defp time_from_string(string), do: Timex.parse!(string, @time_format)
end
