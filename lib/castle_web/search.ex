defmodule CastleWeb.Search do

  def parse_search(params) do
    {
      Map.get(params, "search"),
    }
  end

end
