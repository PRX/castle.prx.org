defmodule Castle.Plugs.Group do
  import Plug.Conn

  @groups %{
    "city" => %{
      name: "city",
      join: "geonames on (city_id = geoname_id)",
      groupby: "city_name",
      limit: 10,
    },
    "metrocode" => %{
      name: "metrocode",
      join: "geonames on (city_id = geoname_id)",
      groupby: "metro_code",
      limit: 10,
    },
    "subdiv1" => %{
      name: "subdiv1",
      join: "geonames on (city_id = geoname_id)",
      groupby: "subdivision_1_iso_code",
      limit: 10,
    },
    "subdiv2" => %{
      name: "subdiv2",
      join: "geonames on (city_id = geoname_id)",
      groupby: "subdivision_2_iso_code",
      limit: 10,
    },
    "country" => %{
      name: "country",
      join: "geonames on (country_id = geoname_id)",
      groupby: "country_name",
      limit: 10,
    },
    "countryiso" => %{
      name: "country",
      join: "geonames on (country_id = geoname_id)",
      groupby: "country_iso_code",
      limit: 10,
    },
    "agentname" => %{
      name: "agentname",
      join: "agentnames on (agent_name_id = agentname_id)",
      groupby: "tag",
      limit: 10
    },
    "agenttype" => %{
      name: "agenttype",
      join: "agentnames on (agent_type_id = agentname_id)",
      groupby: "tag",
      limit: 10
    },
    "agentos" => %{
      name: "agentos",
      join: "agentnames on (agent_os_id = agentname_id)",
      groupby: "tag",
      limit: 10
    },
  }

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> set_grouping()
    |> set_grouping_limit()
  end

  def get(name, limit \\ nil) do
    if Map.has_key?(@groups, name) do
      struct!(BigQuery.Grouping, @groups[name])
      |> Map.put(:limit, limit || @groups[name].limit)
    else
      nil
    end
  end

  defp set_grouping(%{status: nil, params: %{"group" => grouping}} = conn) do
    if Map.has_key?(@groups, grouping) do
      assign conn, :group, struct!(BigQuery.Grouping, @groups[grouping])
    else
      options = @groups |> Map.keys() |> Enum.join(", ")
      conn
      |> send_resp(400, "Bad group param: use one of #{options}")
      |> halt()
    end
  end
  defp set_grouping(conn), do: conn

  defp set_grouping_limit(%{status: nil, assigns: %{group: group}, params: %{"grouplimit" => limit}} = conn) do
    case Integer.parse(limit) do
      {num, ""} ->
        assign conn, :group, Map.put(group, :limit, num)
      _ ->
        conn
        |> send_resp(400, "grouplimit is not an integer")
        |> halt()
    end
  end
  defp set_grouping_limit(conn), do: conn
end
