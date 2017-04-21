defmodule Blogit.Models.Post do
  alias Blogit.Models.Post.Meta

  @enforce_keys [:name, :path, :raw, :html, :meta]
  @posts_folder Application.get_env(:blogit, :posts_folder, "")
  @meta_divider Application.get_env(:blogit, :meta_divider, "<><><><><><><><>")

  defstruct [:name, :path, :raw, :html, :meta]

  def from_file_name(repository_provider, file_name, repository) do
    name = name_from_file(file_name)
    file = repository_provider.local_path
           |> Path.join(@posts_folder) |> Path.join(file_name)

    raw = File.read!(file)
    data = String.split(raw, @meta_divider, trim: true)
           |> Enum.map(&String.trim/1)

    html =
      Earmark.as_html!(String.replace(List.last(data), ~r/^\s*\#\s*.+/, ""))

    meta =
      Meta.from_file_name(repository_provider, file_name, repository, raw, name)

    %__MODULE__{name: name, path: file, raw: raw, html: html, meta: meta}
  end

  def compile_posts(repository_provider, list, repository) when is_list(list) do
    list
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> Enum.reject(fn(f) -> String.starts_with?(f, "slides/") end)
    |> Enum.reject(fn(f) -> String.starts_with?(f, "pages/") end)
    |> Enum.map(fn(file) ->
        __MODULE__.from_file_name(repository_provider, file, repository)
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
    |> Enum.map(&__MODULE__.name_from_file/1)
  end

  def sorted(posts) do
    Enum.sort(posts, fn (post1, post2) ->
      Calendar.NaiveDateTime.before?(
        post2.meta.created_at, post1.meta.created_at
      )
    end)
  end

  def sorted_updated(posts) do
    Enum.sort(posts, fn (post1, post2) ->
      Calendar.NaiveDateTime.before?(
        post2.meta.updated_at, post1.meta.updated_at
      )
    end)
  end

  def reverse(posts) do
    Enum.sort(posts, fn (post1, post2) ->
      Calendar.NaiveDateTime.before?(
        post1.meta.created_at, post2.meta.created_at
      )
    end)
  end

  def collect_by_year_and_month(posts) do
    posts
    |> Enum.reduce(%{}, fn post, map ->
      year = post.meta.created_at.year
      month = post.meta.created_at.month

      month_map = Map.get(map, year, %{})
      month_count = Map.get(month_map, month, 0)
      month_map = Map.merge(month_map, %{month => (month_count + 1)})

      Map.merge(map, %{year => month_map})
    end) |> Map.to_list
    |> Enum.flat_map(fn {year, dates} ->
      Map.to_list(dates)
      |> Enum.map(fn {month, count} -> {year, month, count}end)
    end) |> Enum.sort(fn({year1, month1, _}, {year2, month2, _})->
      cond do
        year1 == year2 -> month2 <= month1
        true -> year2 <= year1
      end
    end)
  end
end
