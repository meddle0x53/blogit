defmodule Blogit.Search do
  alias Blogit.Post

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
