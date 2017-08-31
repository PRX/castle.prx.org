defmodule Castle.PlugsGroupTest do
  use Castle.ConnCase, async: true

  test "groups by country", %{conn: conn} do
    group = get_group(conn, "country")
    assert group.name == "country"
    assert group.join == "geonames on (country_id = geoname_id)"
    assert group.groupby == "country_name"
    assert group.limit == 10
  end

  test "groups by city", %{conn: conn} do
    group = get_group(conn, "city")
    assert group.name == "city"
    assert group.join == "geonames on (city_id = geoname_id)"
    assert group.groupby == "city_name"
    assert group.limit == 10
  end

  test "has no default grouping", %{conn: conn} do
    assert get_group(conn) == nil
  end

  test "overrides limits", %{conn: conn} do
    assert get_group(conn, "country", "11").limit == 11
    assert get_group(conn, "country", "2").limit == 2
  end

  test "validates groupings", %{conn: conn} do
    conn = call_group(conn, "foo")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad group param/i
  end

  test "validates grouping limits", %{conn: conn} do
    conn = call_group(conn, "country", "foo")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/grouplimit is not an integer/i
  end

  test "manually gets a grouping" do
    group = Castle.Plugs.Group.get("city", 4)
    assert group.name == "city"
    assert group.limit == 4
  end

  defp get_group(conn, group \\ nil, limit \\ nil) do
    conn |> call_group(group, limit) |> Map.get(:assigns) |> Map.get(:group)
  end

  defp call_group(conn, group, limit \\ nil) do
    conn |> set_group(group, limit) |> Castle.Plugs.Group.call(%{})
  end

  defp set_group(conn, nil, nil), do: conn
  defp set_group(conn, group, nil), do: Map.merge(conn, %{params: %{"group" => group}})
  defp set_group(conn, group, limit) do
    Map.merge(conn, %{params: %{"group" => group, "grouplimit" => limit}})
  end
end
