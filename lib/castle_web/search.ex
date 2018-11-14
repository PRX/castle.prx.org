defmodule CastleWeb.Search do

  import Ecto.Query

  defp prefix_search(term), do: String.replace(term, ~r/\W/u, "|") <> ":*"

  def filter_title_search(queryable, query) when is_nil(query) do
    queryable
  end
  def filter_title_search(queryable, search_query) do
    queryable
    |> where(fragment(
      "to_tsvector('english', coalesce(title, '') || ' ' || coalesce(subtitle, '')) @@ to_tsquery(?)",
      ^prefix_search(search_query)))
  end

  def parse_search(params) do
    {
      Map.get(params, "search"),
    }
  end

end
