defmodule Castle.Plugs.Group do
  import Plug.Conn

  @groups [
    "geocountry",
    "geosubdiv",
    "geometro",
  ]

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> set_grouping()
    |> set_grouping_limit()
    |> require_group()
  end

  defp set_grouping(%{status: nil, params: %{"group" => grouping}} = conn) do
    if Enum.member?(@groups, grouping) do
      assign conn, :group, %Castle.Grouping{name: grouping}
    else
      conn
      |> send_resp(400, "Bad group param: use one of #{Enum.join(@groups, ", ")}")
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
    conn
    |> send_resp(400, "You must set a group param: #{Enum.join(@groups, ", ")}")
    |> halt()
  end
  defp require_group(conn), do: conn
end
