defmodule Blogit.Models.Post.Search do
  alias Blogit.Models.Post

  @supported_params ~w(author category tags year month q)

  def filter_by_params(posts, params) do
    filters = Map.take(params, @supported_params)
    filters = for {key, val} <- filters, into: %{} do
      {String.to_atom(key), val}
    end

    filters = filter_category(filters)
    tagless_filters = Map.delete filters, :tags
    no_search_filters = Map.delete tagless_filters, :q

    all_by(posts, no_search_filters, [:meta])
    |> filter_tags(filters)
    |> filter_search(filters)
  end

  defp all_by(posts, params, deep) do
    Enum.filter posts, fn entry ->
      Enum.all?(params, fn {key, val} ->
        data = Enum.reduce(deep, entry, fn (current, acc) ->
          Map.fetch!(acc, current)
        end)
        Map.get(data, key) == val
      end)
    end
  end

  defp filter_category(filters = %{category: "uncategorized"}) do
    %{filters | category: nil}
  end
  defp filter_category(filters), do: filters

  defp filter_tags(posts, %{tags: tags}) do
    cond do
      String.match?(tags, ~r/^\w+\s*(,\s*\w+\s*)*$/) ->
        filter_by_tags(tags, posts)
      true -> posts
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

  def search_posts(posts, query) do
    queries = query_to_list(query)

    posts |> Enum.filter(fn (post) ->
      Enum.any?(queries, fn (q) ->
        String.contains?(post.raw, q) || String.contains?(post.meta.title, q)
      end)
    end) |> Post.sorted
  end

  def query_to_list(query) do
    query
    |> String.graphemes
    |> Enum.reduce(%{lead: " ", data: [], temp: []},
      fn (grapheme, current = %{temp: temp, lead: lead, data: data}) ->
        cond do
          grapheme == lead && !Enum.empty?(temp) ->
            %{temp: [], lead: lead, data: data ++ [temp]}
          Enum.empty?(temp) && (grapheme == " " || grapheme == "\"")  ->
            %{current | lead: grapheme}
          (grapheme == " " && lead == "\"") || grapheme != " " ->
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
