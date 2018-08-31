defmodule Castle.PlugsGroupTest do
  use Castle.ConnCase, async: true

  test "groups by country", %{conn: conn} do
    group = get_group(conn, %{group: "geocountry"})
    assert group.name == "geocountry"
    assert group.limit == 10
  end

  test "groups by subdivision", %{conn: conn} do
    group = get_group(conn, %{group: "geosubdiv"})
    assert group.name == "geosubdiv"
    assert group.limit == 10
  end

  test "requires a grouping", %{conn: conn} do
    conn = call_group(conn, %{})
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/you must set a group param/i
  end

  test "parses filters", %{conn: conn} do
    assert get_group(conn, %{group: "geosubdiv"}).filters == nil
    assert get_group(conn, %{group: "geosubdiv", filters: ""}).filters == nil
    assert get_group(conn, %{group: "geosubdiv", filters: "foo,bar=stuff"}).filters == %{foo: true, bar: "stuff"}
    assert get_group(conn, %{group: "geosubdiv", filters: "foo:false,bar"}).filters == %{foo: false, bar: true}
    assert get_group(conn, %{group: "geosubdiv", filters: "foo=true,bar:"}).filters == %{foo: true, bar: true}
  end

  test "overrides limits", %{conn: conn} do
    assert get_group(conn, %{group: "geocountry", limit: "11"}).limit == 11
    assert get_group(conn, %{group: "geocountry", limit: "2"}).limit == 2
  end

  test "validates groupings", %{conn: conn} do
    conn = call_group(conn, %{group: "foo"})
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad group param/i
  end

  test "validates grouping limits", %{conn: conn} do
    conn = call_group(conn, %{group: "geocountry", limit: "foo"})
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/limit is not an integer/i
  end

  defp get_group(conn, params) do
    conn |> call_group(params) |> Map.get(:assigns) |> Map.get(:group)
  end

  defp call_group(conn, params) do
    conn |> set_group(params) |> Castle.Plugs.Group.call(%{})
  end

  defp set_group(conn, params) do
    str_params = Map.new(params, fn({k, v}) -> {Atom.to_string(k), v} end)
    Map.merge(conn, %{params: str_params})
  end
end
