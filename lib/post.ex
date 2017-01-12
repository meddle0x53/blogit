defmodule Blogit.Post do
  use Timex

  @enforce_keys [:name, :path, :raw, :html]

  defstruct [:name, :path, :raw, :html, :created_at, :updated_at, :author]

  def from_file_name(file_name, folder, repository) do
    name = file_name |> String.downcase |> String.trim_trailing(".md")
    file = Path.join(folder, file_name)
    raw = File.read!(file)
    html = Earmark.to_html(raw)
    {:ok, author} =
      Git.log(repository, ["--reverse", "--format=%an <%ae>", file_name])
    {:ok, created_at} =
      Git.log(repository, ["--reverse", "--format=%ci", file_name])
    {:ok, updated_at} =
      Git.log(repository, ["-1", "--format=%ci", file_name])

    format = "{YYYY}-{M}-{D} {h24}:{m}:{s} {Z}"
    created_at = created_at
                 |> String.split("\n")
                 |> List.first
                 |> String.trim
                 |> Timex.parse!(format)

    %__MODULE__{
      name: name, path: file, raw: raw, html: html,
      updated_at: Timex.parse!(String.trim(updated_at), format),
      created_at: created_at,
      author: String.trim(List.first(String.split(author, "\n")))
    }
  end
end
