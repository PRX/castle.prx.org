defmodule Castle.PlugsParseIntTest do
  use Castle.ConnCase, async: true

  test "parses integer params", %{conn: conn} do
    conn = call_parse_int(conn, "id", "987")
    assert conn.params["id"] == 987
  end

  test "renders 404 when unable to parse", %{conn: conn} do
    conn = call_parse_int(conn, "id", "foo")
    assert conn.status == 404
    assert conn.halted == true
    assert conn.resp_body =~ ~r/foo is not an integer/i
  end

  test "ignores missing params", %{conn: conn} do
    conn = call_parse_int(conn, "id")
    assert conn.halted == false
    assert Map.has_key?(conn.params, "id") == false
  end

  defp call_parse_int(conn, name, val) do
    conn
    |> Map.merge(%{params: %{name => val}})
    |> Castle.Plugs.ParseInt.call(name)
  end

  defp call_parse_int(conn, name) do
    conn |> Castle.Plugs.ParseInt.call(name)
  end
end
