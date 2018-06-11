defmodule Castle.PlugsGroupTest do
  use Castle.ConnCase, async: true

  test "groups by country", %{conn: conn} do
    group = get_group(conn, "geocountry")
    assert group.name == "geocountry"
    assert group.limit == 10
  end

  test "groups by subdivision", %{conn: conn} do
    group = get_group(conn, "geosubdiv")
    assert group.name == "geosubdiv"
    assert group.limit == 10
  end

  test "requires a grouping", %{conn: conn} do
    conn = call_group(conn, nil, nil)
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/you must set a group param/i
  end

  test "overrides limits", %{conn: conn} do
    assert get_group(conn, "geocountry", "11").limit == 11
    assert get_group(conn, "geocountry", "2").limit == 2
  end

  test "validates groupings", %{conn: conn} do
    conn = call_group(conn, "foo")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad group param/i
  end

  test "validates grouping limits", %{conn: conn} do
    conn = call_group(conn, "geocountry", "foo")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/limit is not an integer/i
  end

  defp get_group(conn, group, limit \\ nil) do
    conn |> call_group(group, limit) |> Map.get(:assigns) |> Map.get(:group)
  end

  defp call_group(conn, group, limit \\ nil) do
    conn |> set_group(group, limit) |> Castle.Plugs.Group.call(%{})
  end

  defp set_group(conn, nil, nil), do: conn
  defp set_group(conn, group, nil), do: Map.merge(conn, %{params: %{"group" => group}})
  defp set_group(conn, group, limit) do
    Map.merge(conn, %{params: %{"group" => group, "limit" => limit}})
  end
end
