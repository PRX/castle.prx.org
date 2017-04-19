defmodule Castle.PlugsBasicAuthTest do
  use Castle.ConnCase, async: true

  @tag :no_auth
  test "returns 401 without auth header", %{conn: conn} do
    conn = call_basic_auth(conn)
    assert conn.status == 401
    assert conn.halted == true
    assert conn.resp_body =~ ~r/unauthorized/i
  end

  @tag :no_auth
  test "returns 401 with non-basic auth header", %{conn: conn} do
    conn = call_basic_auth(conn, Base.encode64("foo:bar"))
    assert conn.status == 401
    assert conn.halted == true
    assert conn.resp_body =~ ~r/unauthorized/i
  end

  @tag :no_auth
  test "returns 401 with bad basic auth", %{conn: conn} do
    conn = call_basic_auth(conn, "Basic " <> Base.encode64("foo:bee"))
    assert conn.status == 401
    assert conn.halted == true
    assert conn.resp_body =~ ~r/unauthorized/i
  end

  @tag :no_auth
  test "passes with good basic auth", %{conn: conn} do
    conn = call_basic_auth(conn, "Basic " <> Base.encode64("foo:bar"))
    assert is_nil conn.status
    assert conn.halted == false
  end

  @tag :no_auth
  test "passes with nil user and pass configured", %{conn: conn} do
    conn = call_basic_auth_unconfigured(conn)
    assert is_nil conn.status
    assert conn.halted == false
  end

  defp call_basic_auth(conn, auth \\ nil) do
    conn |> set_auth(auth) |> Castle.Plugs.BasicAuth.call(user: "foo", pass: "bar")
  end
  defp call_basic_auth_unconfigured(conn, auth \\ nil) do
    conn |> set_auth(auth) |> Castle.Plugs.BasicAuth.call(user: nil, pass: nil)
  end

  defp set_auth(conn, nil), do: conn
  defp set_auth(conn, auth), do: put_req_header(conn, "authorization", auth)
end
