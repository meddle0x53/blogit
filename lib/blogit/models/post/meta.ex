defmodule Blogit.Models.Post.Meta do
  @moduledoc """
  Represents the meta-data of a post.

  Provides a function to read/parse the meta information from a file.
  All the meta-fields have default values.

  The meta information can be stored at the top of the
  markdown file's content in YAML format. The markdown content and meta-data
  are divided using the `\n---\n`. This yml meta data has the highest priority
  when `Blogit.Models.Post.Meta` struct is created from a post source file.

  With lower priority are the defaults and values read from the repository
  containing the file.
  """

  require Logger

  alias Calendar.NaiveDateTime.Parse
  alias Blogit.RepositoryProvider, as: Repository

  import Blogit.Settings

  @type t :: %__MODULE__{
          author: String.t(),
          title: String.t(),
          category: String.t(),
          published: boolean,
          tags: [String.t()],
          title_image_path: String.t(),
          pinned: boolean,
          year: String.t(),
          month: String.t(),
          language: String.t(),
          preview: String.t(),
          name: String.t(),
          created_at: Calendar :: NaiveDateTime.t(),
          updated_at: Calendar :: NaiveDateTime.t()
        }
  defstruct [
    :created_at,
    :updated_at,
    :author,
    :title,
    :category,
    :tags,
    :published,
    :title_image_path,
    :pinned,
    :year,
    :month,
    :language,
    :preview,
    :name
  ]

  @doc """
  Creates a `Blogit.Models.Post.Meta` struct using the source file of a post,
  its raw data, the language of the post, the name of the post  and the
  repository containing the blog data.

  The given `raw_meta` should be list with two elements, the first element
  should be an YAML string containing the meta-data and the second the post's
  raw content.
  """
  @spec from_file(String.t(), Repository.t(), [String.t()], String.t(), String.t()) :: t
  def from_file(file_path, repository, raw_data, name, language) do
    raw_meta = List.first(raw_data)
    raw = List.last(raw_data)

    meta = merge_with_inline(raw_meta)
    post_data = %{raw: raw, name: name, language: language}

    create_from_map(meta, file_path, repository, post_data)
  end

  @doc """
  Sorts a list of `Blogit.Models.Post.Meta` strucs by the given field.
  The field can be either `:created_at` or `updated_at`.

  By default this field is `created_at`. Note that the sort is descending.

  ## Examples

      iex> alias Blogit.Models.Post.Meta
      iex> metas = [
      ...>   %Meta{created_at: ~N[2017-02-14 22:23:12], name: "meta1"},
      ...>   %Meta{created_at: ~N[2017-04-22 14:53:45], name: "meta2"},
      ...>   %Meta{created_at: ~N[2017-03-01 07:42:56], name: "meta3"}
      ...> ]
      iex> Meta.sorted(metas) |> Enum.map(fn (meta) -> meta.name end)
      ~w[meta2 meta3 meta1]

      iex> alias Blogit.Models.Post.Meta
      iex> metas = [
      ...>   %Meta{updated_at: ~N[2017-03-01 07:42:56], name: "meta2"},
      ...>   %Meta{updated_at: ~N[2017-02-14 22:23:12], name: "meta1"},
      ...>   %Meta{updated_at: ~N[2017-04-20 12:23:12], name: "meta3"}
      ...> ]
      iex> Meta.sorted(metas, :updated_at) |> Enum.map(&(&1.name))
      ~w[meta3 meta2 meta1]
  """
  @spec sorted([t], atom) :: [t]
  def sorted(metas, field \\ :created_at) do
    Enum.sort(metas, fn meta1, meta2 ->
      Calendar.NaiveDateTime.before?(
        Map.get(meta2, field),
        Map.get(meta1, field)
      )
    end)
  end

  ###########
  # Private #
  ###########

  defp merge_with_inline(raw_meta) when is_nil(raw_meta), do: %{}
  defp merge_with_inline(raw_meta) do
    {:ok, meta} = YamlElixir.read_from_string(raw_meta)
    meta
  end

  defp create_from_map(data, file_path, repository, %{raw: raw, name: name, language: language})
       when is_map(data) do
    path = Path.join(posts_folder(), file_path)


    created_at = data["created_at"]
    updated_at = data["updated_at"]
    author = data["author"]
    {created_at_from_provider, updated_at2_from_provider, author_from_provider} =
      if is_nil(created_at) || is_nil(updated_at) || is_nil(author) do
        Logger.info("Get meta from REPO using git log: " <> file_path)
        file_info = repository.provider.file_info(repository.repo, path)
        {
          file_info[:created_at] || (DateTime.utc_now() |> DateTime.to_iso8601()),
          updated_at || file_info[:updated_at] || (DateTime.utc_now() |> DateTime.to_iso8601()),
          author || file_info[:author] || "Anonymous"
        }
      else
        {nil, nil, nil}
      end

    created_at = created_at || created_at_from_provider
    updated_at = updated_at || updated_at2_from_provider
    author = author || author_from_provider


    {:ok, created_at, _} = Parse.iso8601(created_at)
    {:ok, updated_at, _} = Parse.iso8601(updated_at)

    index = nth_index_of(raw, 0, 0, max_lines_in_preview())

    {:ok, preview, _} =
      raw
      |> String.split_at(index)
      |> elem(0)
      |> String.replace(~r/^\s*\#\s*.+/, "")
      |> Kernel.<>(find_all_references(raw))
      |> Earmark.as_html()

    tags = Map.get(data, "tags", [])

    %__MODULE__{
      created_at: created_at,
      updated_at: updated_at,
      author: author,
      title: data["title"] || retrieve_title(raw, name),
      tags: tags |> Enum.map(&Kernel.to_string/1),
      published: Map.get(data, "published", true),
      name: name,
      category: data["category"],
      year: Integer.to_string(created_at.year),
      month: Integer.to_string(created_at.month),
      title_image_path: data["title_image_path"],
      pinned: data["pinned"] || false,
      preview: preview,
      language: language || default_language()
    }
  end

  defp create_from_map(_, file_path, repository, post_data) do
    create_from_map(%{}, file_path, repository, post_data)
  end

  defp nth_index_of(<<>>, index, _, _), do: index
  defp nth_index_of(<<"\n", _::binary>>, index, n, n), do: index

  defp nth_index_of(<<"\n", rest::binary>>, index, current, n) do
    nth_index_of(rest, index + 1, current + 1, n)
  end

  defp nth_index_of(<<_::utf8, rest::binary>>, index, current, n) do
    nth_index_of(rest, index + 1, current, n)
  end

  defp retrieve_title(raw, name) do
    guess_title(Regex.named_captures(~r/^\s*\#\s*(?<title>.+)$/m, raw), name)
  end

  defp guess_title(%{"title" => title}, _), do: title

  defp guess_title(_, name) do
    name
    |> String.split(~r{[^A-Za-z0-9]})
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @references_regex ~r/^[ ]{0,3}(?:\[(.+?)\][ ]?:)[ ]*\n?[ ]*(?:<(.+?)>|(\S+?))[ ]*\n?[ ]*(?:(?<=\s)["(](.*?)[")][ ]*)?(?:\n+|\Z)/mi
  defp find_all_references(raw) do
    @references_regex
    |> Regex.scan(raw, capture: :all)
    |> Enum.map(fn match -> match |> List.first() |> String.trim() end)
    |> Enum.uniq()
    |> Enum.reduce("", fn reference, references ->
      references <> "\n" <> reference
    end)
  end
end
