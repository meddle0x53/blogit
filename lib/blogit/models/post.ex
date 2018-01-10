defmodule Blogit.Models.Post do
  @moduledoc """
  A module holding the representation of a post in a blog and helper functions
  for it.

  The `Blogit.Models.Post` struct contains an unique name of the post,
  which identifies it, the raw content of the post in markdown,
  html version of the post content and meta information.

  The meta information is contained in a `Blogit.Models.Post.Meta` struct.

  Usually a post is created by invoking the `Blogit.Models.Post.from_file/2`
  function.
  This function takes a module implementing the `Blogit.RepositoryProvider`
  behaviour for access to a repository, a file path and a
  `Blogit.RepositoryProvider` struct.
  It uses them to read the file and generate the `Bogit.Models.Post` struct.

  The `Blogit.Models.Post.compile_posts/2` function is able to create a list
  of multiple `Blogit.Models.Post` structs using a list of files and a
  `Blogit.RepositoryProvider` struct.

  The module contains a set of utility methods for working with
  `Blogit.Models.Post` structs.
  """

  alias Blogit.Models.Post.Meta
  alias Blogit.RepositoryProvider, as: Repository
  import Blogit.Settings

  @type t :: %__MODULE__{
          name: String.t(),
          raw: String.t(),
          html: String.t(),
          meta: Meta.t()
        }
  @enforce_keys [:name, :raw, :html, :meta]
  defstruct [:name, :raw, :html, :meta]

  @doc """
  Creates a `Blogit.Models.Post` struct from a file stored in a repository.

  The name of the file is used as the name of the post.
  For example the struct created from the file `some_post.md`
  will have `post.name == "some_post"`.

  The given `file_path` should be located in the given `repository`.

  The result struct will have `meta` created by invoking
  `Blogit.Models.Post.Meta.from_file/5` with the given `file_path`,
  `repository` and `language`, the `name` of the post and the markdown data
  read from the file.

  If the source file located at the given `file_path` doesn't exist, the
  atom `:source_file_not_found` is returned as a result.

  If the meta data of the post to be created has `published: false`,
  `post.html` won't be generated and will be `nil`.
  """
  @type from_file_result :: t | :source_file_not_found
  @spec from_file(String.t(), Repository.t(), String.t()) :: from_file_result
  def from_file(file_path, repository, language) do
    name = name_from_file(file_path, language)

    case repository.provider.read_file(file_path, posts_folder()) do
      {:error, _} ->
        :source_file_not_found

      {:ok, raw} ->
        data =
          if String.contains?(raw, meta_divider()) do
            raw
            |> String.split(meta_divider(), trim: true)
            |> Enum.map(&String.trim/1)
          else
            [nil, String.trim(raw)]
          end

        meta = Meta.from_file(file_path, repository, data, name, language)

        if meta.published do
          html = Earmark.as_html!(String.replace(List.last(data), ~r/^\s*\#\s*.+/, ""))
          %__MODULE__{name: name, raw: raw, html: html, meta: meta}
        else
          %__MODULE__{name: name, raw: raw, html: nil, meta: meta}
        end
    end
  end

  @doc """
  Returns a map of maps. For every supported language, returned by invoking
  `Blogit.Settings.languages/0`, the result of a call to this function will
  have a key, representing it.
  The value for every such key will be a map with keys the names
  of the posts created from parsing the files in the directory representing the
  language in the given list of paths and values the post structs created.

  Uses from_file/2 to parse the files and create the `Blogit.Models.Post`
  structs.

  Skips all the non-markdown files as well as the ones that mark the post
  content as not published or does not exist in the given `repository`.
  """
  @spec compile_posts([String.t()], Repository.t()) :: %{String.t() => %{atom => t}}
  def compile_posts(list, repository) when is_list(list) do
    file_paths =
      list
      |> Enum.filter(fn f -> String.ends_with?(f, ".md") end)
      |> Enum.map(&Path.split/1)

    primary_language = default_language()

    languages()
    |> Enum.reduce(%{}, fn language, current ->
      paths =
        file_paths
        |> Enum.filter(fn path ->
          [prefix | _] = path

          prefix == language ||
            (language == primary_language && !Enum.member?(languages(), prefix))
        end)
        |> Enum.map(&Path.join/1)
        |> Enum.map(fn file -> from_file(file, repository, language) end)
        |> Enum.reject(&(&1 == :source_file_not_found || is_nil(&1.raw)))
        |> Enum.filter(& &1.meta.published)
        |> Enum.map(fn post -> {String.to_atom(post.name), post} end)
        |> Enum.into(%{})

      Map.put(current, language, paths)
    end)
  end

  @doc """
  Retrieves unique names, which can be used as names of posts, from a list
  of file names.

  ## Examples

      iex> Blogit.Models.Post.names_from_files(["SomeFile.md", "another.md"])
      ...> |> Enum.map(&(elem(&1, 1)))
      [:somefile, :another]

      iex> Blogit.Models.Post.names_from_files(["one/two/name.md"])
      ...> |> Enum.map(&(elem(&1, 1)))
      [:one_two_name]
  """
  @spec names_from_files([String.t()]) :: [String.t()]
  def names_from_files(files) do
    files
    |> Enum.filter(fn f -> String.ends_with?(f, ".md") end)
    |> Enum.map(fn path ->
      [prefix | _] = Path.split(path)

      {languages() |> Enum.find(default_language(), &(prefix == &1)), path}
    end)
    |> Enum.map(fn {lang, path} ->
      {lang, path |> name_from_file(lang) |> String.to_atom()}
    end)
  end

  @doc """
  Calculates a list of tuples of three elements from the given list of posts.

  The first element of a tuple is a year.
  The second is a month number.
  The third is a counter - how many posts are created during that month
  and that year.

  The tuples are sorted from the newest to the oldest, using the years
  and the months.

  ## Examples

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2016-04-14 22:23:12]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-22 14:53:45]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-02-01 07:42:56]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-20 12:23:12]}
      ...>   }
      ...> ]
      iex> Blogit.Models.Post.collect_by_year_and_month(posts)
      [{2017, 4, 2}, {2017, 2, 1}, {2016, 4, 1}]
  """
  @type year_month_count_result :: {pos_integer, 1..12, non_neg_integer}
  @spec collect_by_year_and_month([t]) :: [year_month_count_result]
  def collect_by_year_and_month(posts) do
    posts
    |> Enum.reduce(%{}, fn post, map ->
      year = post.meta.created_at.year
      month = post.meta.created_at.month

      month_map = Map.get(map, year, %{})
      month_count = Map.get(month_map, month, 0)
      month_map = Map.merge(month_map, %{month => month_count + 1})

      Map.merge(map, %{year => month_map})
    end)
    |> Map.to_list()
    |> Enum.flat_map(fn {year, dates} ->
      dates
      |> Map.to_list()
      |> Enum.map(fn {month, count} -> {year, month, count} end)
    end)
    |> Enum.sort(fn {year1, month1, _}, {year2, month2, _} ->
      case year1 == year2 do
        true -> month2 <= month1
        false -> year2 <= year1
      end
    end)
  end

  ###########
  # Private #
  ###########

  defp name_from_file(file_name, language) do
    file_name
    |> Path.split()
    |> Enum.filter(&(&1 != language))
    |> Enum.join("_")
    |> String.downcase()
    |> String.trim_trailing(".md")
  end
end
