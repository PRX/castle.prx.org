defmodule Castle.PlugsAuthTest do
  use Castle.ConnCase, async: false

  import Mock

  test "mocks user auth", %{conn: conn} do
    System.put_env("DEV_AUTH", "123,456")
    conn = Castle.Plugs.Auth.call(conn, [])
    assert Map.has_key?(conn, :prx_user)
    assert conn.prx_user.id == 999_999
    assert Map.keys(conn.prx_user.auths) == ["123", "456"]
    assert conn.prx_user.auths["123"] == %{"castle:read_private" => true}
    assert conn.prx_user.auths["456"] == %{"castle:read_private" => true}
  end

  test "does not mock auth in production", %{conn: conn} do
    with_mock Mix, [:passthrough], env: fn -> :prod end do
      fake_call = fn conn, _opts -> Map.put(conn, :prx_user, :called) end

      with_mock PrxAuth.Plug, call: fake_call do
        conn = Castle.Plugs.Auth.call(conn, [])
        assert conn.prx_user == :called
      end
    end
  end

  test "mocks wildcard auth from the database", %{conn: conn} do
    Castle.Repo.insert!(%Castle.Podcast{id: 1, account_id: 234})
    Castle.Repo.insert!(%Castle.Podcast{id: 2, account_id: 567})
    Castle.Repo.insert!(%Castle.Podcast{id: 3, account_id: 234})

    System.put_env("DEV_AUTH", "*")
    conn = Castle.Plugs.Auth.call(conn, [])
    assert Map.has_key?(conn, :prx_user)
    assert conn.prx_user.id == 999_999
    assert Map.keys(conn.prx_user.auths) == ["234", "567"]
    assert conn.prx_user.auths["234"] == %{"castle:read_private" => true}
    assert conn.prx_user.auths["567"] == %{"castle:read_private" => true}
  end
end
