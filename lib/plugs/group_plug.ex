defmodule Castle.Plugs.Group do
  import Plug.Conn

  @groups %{
    "agentname" => %{
      name: "agentname",
      ranks: Castle.Rollup.Query.AgentRanks,
      totals: Castle.Rollup.Query.AgentTotals,
      labels: Castle.Label.Agent,
    },
    "agenttype" => %{
      name: "agenttype",
      ranks: Castle.Rollup.Query.AgentRanks,
      totals: Castle.Rollup.Query.AgentTotals,
      labels: Castle.Label.Agent,
    },
    "agentos" => %{
      name: "agentos",
      ranks: Castle.Rollup.Query.AgentRanks,
      totals: Castle.Rollup.Query.AgentTotals,
      labels: Castle.Label.Agent,
    },
    "geocountry" => %{
      name: "geocountry",
      ranks: Castle.Rollup.Query.GeoRanks,
      totals: Castle.Rollup.Query.GeoTotals,
      labels: Castle.Label.GeoCountry,
    },
    "geosubdiv" => %{
      name: "geosubdiv",
      ranks: Castle.Rollup.Query.GeoRanks,
      totals: Castle.Rollup.Query.GeoTotals,
      labels: Castle.Label.GeoSubdiv,
    },
    "geometro" => %{
      name: "geometro",
      ranks: Castle.Rollup.Query.GeoRanks,
      totals: Castle.Rollup.Query.GeoTotals,
      labels: Castle.Label.GeoMetro,
    },
  }

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> set_grouping()
    |> set_grouping_limit()
    |> require_group()
  end

  defp set_grouping(%{status: nil, params: %{"group" => grouping}} = conn) do
    if Map.has_key?(@groups, grouping) do
      assign conn, :group, struct!(Castle.Grouping, @groups[grouping])
    else
      options = @groups |> Map.keys() |> Enum.join(", ")
      conn
      |> send_resp(400, "Bad group param: use one of #{options}")
      |> halt()
    end
  end
  defp set_grouping(conn), do: conn

  defp set_grouping_limit(%{status: nil, assigns: %{group: group}, params: %{"limit" => limit}} = conn) do
    case Integer.parse(limit) do
      {num, ""} ->
        assign conn, :group, Map.put(group, :limit, num)
      _ ->
        conn
        |> send_resp(400, "limit is not an integer")
        |> halt()
    end
  end
  defp set_grouping_limit(conn), do: conn

  defp require_group(%{status: nil, assigns: %{group: _group}} = conn), do: conn
  defp require_group(%{status: nil} = conn) do
    options = @groups |> Map.keys() |> Enum.join(", ")
    conn
    |> send_resp(400, "You must set a group param: #{options}")
    |> halt()
  end
  defp require_group(conn), do: conn
end
