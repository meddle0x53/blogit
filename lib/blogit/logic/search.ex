defmodule Blogit.Logic.Search do
  @moduledoc """
  Contains a function for filtering and test-searching posts.

  Lists of Post structures can be filtered by 'author', 'category', 'tags',
  'year' and 'month'.

  The content and the title of lists of `Blogit.Models.Post`s can be searched using a query.
  """

  @supported_params ~w(author category tags year month q)

  @type search_value :: String.t
  @type posts :: [Blogit.Models.Post.t]

  @doc """
  Filters a list of `Blogit.Models.Post` structures using a map meta fields
  to filter by and/or
  search query to match to their contents and/or titles.

  The map parameter supports zero or more of the following keys:
  * "author" - Used to filter Posts by their `.meta.author` field.
  * "category" - Used to filter Posts by their `.meta.category` field.
  * "tags" - Used to filter Posts by their `.meta.tags` field.
    The value for this key should a string of comma separated tags.
  * "year" - Used to filter Posts by their `.meta.year` field.
  * "month" - Used to filter Posts by their `.meta.month` field.
  * "q" - A query to filter Posts by their content or title. Support text in
    double quotes in order to search for phrases.

  If the map contains other keys, they'll be ignored.

  ## Examples

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "one", raw: "", html: "",
      ...>     meta: %Meta{author: "meddle", category: "Primary"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "two", raw: "", html: "",
      ...>     meta: %Meta{author: "valo", category: "Secondary"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "three", raw: "", html: "",
      ...>     meta: %Meta{author: "Reductions", category: "Other"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "four", raw: "", html: "",
      ...>     meta: %Meta{author: "meddle", category: "Other"}
      ...>   }
      ...> ]
      iex> filter = %{"author" => "meddle"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one", "four"]
      iex> filter = %{"category" => "Other"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["three", "four"]

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "one", raw: "", html: "",
      ...>     meta: %Meta{tags: ["one", "едно", "super"]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "two", raw: "", html: "",
      ...>     meta: %Meta{tags: ["two", "две", "super"]}
      ...>   }
      ...> ]
      iex> filter = %{"tags" => "super, one"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one"]

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "one", raw: "", html: "",
      ...>     meta: %Meta{year: "2017", month: "4"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "two", raw: "", html: "",
      ...>     meta: %Meta{year: "2016", month: "4"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "three", raw: "", html: "",
      ...>     meta: %Meta{year: "2017", month: "3"}
      ...>   }
      ...> ]
      iex> filter = %{"year" => "2017"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one", "three"]
      iex> filter = %{"month" => "4"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one", "two"]
      iex> filter = %{"month" => "4", "year" => "2017"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one"]

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "one", raw: "Something about Processes - stuff", html: "",
      ...>     meta: %Meta{author: "meddle", title: "Processes"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "two", raw: "Modules contain functions!", html: "",
      ...>     meta: %Meta{author: "valo", title: "Modules And Functions"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "three", raw: "Mix is one of the coolest things", html: "",
      ...>     meta: %Meta{author: "Reductions", title: "Mix And Tests"}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "four", raw: "Linked things make difference", html: "",
      ...>     meta: %Meta{author: "meddle", title: "Processes And Links"}
      ...>   }
      ...> ]
      iex> filter = %{"q" => "Process"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["one", "four"]
      iex> filter = %{"q" => "Tests"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["three"]
      iex> filter = %{"q" => ~s("coolest things")}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      ["three"]
      iex> filter = %{"q" => ~s("coolest things"), "author" => "meddle"}
      iex> filtered = Blogit.Logic.Search.filter_by_params(posts, filter)
      iex> filtered |> Enum.map(fn (post) -> post.name end)
      []
  """
  @spec filter_by_params(posts, %{String.t => search_value}) :: posts
  def filter_by_params(posts, params) do
    filters = Map.take(params, @supported_params)
    filters = for {key, val} <- filters, into: %{} do
      {String.to_atom(key), val}
    end

    filters = filter_category(filters)
    tagless_filters = Map.delete filters, :tags
    no_search_filters = Map.delete tagless_filters, :q

    posts
    |> all_by(no_search_filters, [:meta])
    |> filter_tags(filters)
    |> filter_search(filters)
  end

  ###########
  # Private #
  ###########

  defp search_posts(posts, query) do
    queries = query_to_list(query)

    posts |> Enum.filter(fn (post) ->
      Enum.any?(queries, fn (q) ->
        String.contains?(post.raw, q) || String.contains?(post.meta.title, q)
      end)
    end)
  end

  defp all_by(posts, params, deep) do
    Enum.filter posts, fn entry ->
      Enum.all?(params, fn {key, val} ->
        deep_check_equal(deep, entry, key, val)
      end)
    end
  end

  defp deep_check_equal(deep, entry, key, val) do
    data = Enum.reduce(deep, entry, fn (current, acc) ->
      Map.fetch!(acc, current)
    end)
    Map.get(data, key) == val
  end

  defp filter_category(%{category: "uncategorized"} = filters) do
    %{filters | category: nil}
  end
  defp filter_category(filters), do: filters

  defp filter_tags(posts, %{tags: tags}) do
    if String.match?(tags, ~r/^\w+\s*(,\s*\w+\s*)*$/) do
      filter_by_tags(tags, posts)
    else
      posts
    end
  end

  defp filter_tags(posts, _), do: posts

  defp filter_search(posts, %{q: query}), do: search_posts(posts, query)
  defp filter_search(posts, _), do: posts

  defp filter_by_tags(tags, posts) do
    tag_set = tags
              |> String.split(",", trim: true)
              |> Enum.map(&String.trim/1)
              |> Enum.into(MapSet.new)

    Enum.filter(posts, fn (post) ->
      MapSet.subset?(tag_set, post.meta.tags |> Enum.into(MapSet.new))
    end)
  end

  defp query_to_list(query) do
    query
    |> String.graphemes
    |> Enum.reduce(%{lead: " ", data: [], temp: []},
      fn (grapheme, current = %{temp: temp, lead: lead, data: data}) ->
        cond do
          grapheme == lead && !Enum.empty?(temp) ->
            %{temp: [], lead: lead, data: data ++ [temp]}
          Enum.empty?(temp) && (grapheme == " " || grapheme == ~s("))  ->
            %{current | lead: grapheme}
          (grapheme == " " && lead == ~s(")) || grapheme != " " ->
            %{current | temp: [grapheme | temp]}
        end
      end)
    |> data_map_to_list
    |> Enum.map(fn (list) -> list |> Enum.reverse |> Enum.join("") end)
  end

  defp data_map_to_list(%{data: data, temp: temp}) do
    case Enum.empty?(temp) do
      false -> data ++ [temp]
      true -> data
    end
  end
end
