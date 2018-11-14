defmodule CastleWeb.Search do

  import Ecto.Query

  def prefix_search(query) do
    ends_with_whitespace = Regex.match?(~r/\s$/, query)

    # append a suffix wildcard for prefix searching
    query = if !ends_with_whitespace do
      query <> ":*"
    else
      query
    end

    query = String.trim(query)

    # Join search terms with an "|" OR
    String.replace(query, ~r/[\s]+/u, "|")
  end

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
