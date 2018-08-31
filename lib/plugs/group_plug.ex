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
    |> set_grouping_filters()
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

  defp set_grouping_filters(%{status: nil, assigns: %{group: group}, params: %{"filters" => filters}} = conn) do
    case parse_filters String.split(filters, ",") do
      [] -> conn
      parsed ->
        assign conn, :group, Map.put(group, :filters, Map.new(parsed))
    end
  end
  defp set_grouping_filters(conn), do: conn

  defp parse_filters([]), do: []
  defp parse_filters([""]), do: []
  defp parse_filters([filter | rest]) do
    val = case String.split(filter, ["=", ":"], parts: 2, trim: true) do
      [key] -> {String.to_atom(key), true}
      [key, "true"] -> {String.to_atom(key), true}
      [key, "false"] -> {String.to_atom(key), false}
      [key, val] -> {String.to_atom(key), val}
    end
    [val] ++ parse_filters(rest)
  end

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
