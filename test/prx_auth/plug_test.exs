defmodule PrxAuth.PlugTest do
  use Castle.ConnCase, async: false

  import Mock

  defmacro with_verify(val, do: expression) do
    quote do
      verify = fn(_cert, _iss, _jwt) -> unquote(val) end
      with_mock PrxAuth.Token, [verify: verify] do
        unquote(expression)
      end
    end
  end

  test "requires auth", %{conn: conn} do
    with_verify {:ok, %{}} do
      assert call_prx_auth(conn, "token", "id.prx.org", true).status == nil
    end
    for resp <- [:invalid, :bad_issuer, :no_token, :blah] do
      with_verify {resp} do
        assert call_prx_auth(conn, "token", "id.prx.org", true).status == 401
      end
    end
  end

  test "does not require auth", %{conn: conn} do
    with_verify {:ok, %{}} do
      assert call_prx_auth(conn, "token", "id.prx.org", false).status == nil
    end
    for resp <- [:bad_issuer, :no_token] do
      with_verify {resp} do
        assert call_prx_auth(conn, "token", "id.prx.org", false).status == nil
      end
    end
    for resp <- [:invalid, :blah] do
      with_verify {resp} do
        assert call_prx_auth(conn, "token", "id.prx.org", false).status == 401
      end
    end
  end

  test "decodes user", %{conn: conn} do
    with_verify {:ok, %{"sub" => 1234, "scope" => "read", "aur" => %{123 => "write"}}} do
      conn = call_prx_auth(conn, "token", "id.prx.org", true)
      assert conn.status == nil
      assert Map.has_key?(conn, :prx_user)
      assert conn.prx_user.id == 1234
      assert conn.prx_user.auths["123"]["read"] == true
      assert conn.prx_user.auths["123"]["write"] == true
    end
  end

  defp call_prx_auth(conn, auth, issuer, reqd) do
    conn |> set_auth(auth) |> PrxAuth.Plug.call(iss: issuer, required: reqd)
  end

  defp set_auth(conn, nil), do: conn
  defp set_auth(conn, auth), do: put_req_header(conn, "authorization", auth)
end
