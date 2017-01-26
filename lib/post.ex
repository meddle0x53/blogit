defmodule Blogit.Post do
  alias Blogit.GitRepository

  @enforce_keys [:name, :path, :raw, :html, :meta]
  @time_format "{YYYY}-{M}-{D} {h24}:{m}:{s} {Z}"
  @posts_folder Application.get_env(:blogit, :posts_folder, "/")
  @meta_divider Application.get_env(:blogit, :meta_divider, "<><><><><><><><>")

  defstruct [
    :name, :path, :raw, :html, :meta
  ]

  def from_file_name(file_name, repository) do
    name = name_from_file(file_name)
    file = GitRepository.local_path
           |> Path.join(@posts_folder) |> Path.join(file_name)

    raw = File.read!(file)
    data = String.split(raw, @meta_divider, trim: true)

    html = Earmark.to_html(String.replace(List.last(data), ~r/^\s*\#\s*.+/, ""))

    %__MODULE__{
      name: name, path: file, raw: raw, html: html,
      meta: Blogit.Meta.from_file_name(file_name, repository, raw, name)
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
end
