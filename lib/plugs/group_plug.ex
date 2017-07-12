defmodule Castle.Plugs.Group do
  import Plug.Conn

  @groups %{
    "city" => %{
      key: "city_id",
      display: "city_name",
      limit: 10,
    },
    "country" => %{
      key: "country_id",
      display: "country_name",
      limit: 10,
    },
  }

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> set_grouping()
    |> set_grouping_limit()
  end

  defp set_grouping(%{status: nil, params: %{"group" => grouping}} = conn) do
    if Map.has_key?(@groups, grouping) do
      assign conn, :group, @groups[grouping]
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
