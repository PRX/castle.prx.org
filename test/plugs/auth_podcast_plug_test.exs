defmodule Castle.PlugsAuthPodcastTest do
  use Castle.ConnCase, async: true

  setup do
    System.put_env("DEV_AUTH", "999")
    []
  end

  test "authorizes podcasts", %{conn: conn} do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, account_id: 999})
    conn = call_auth_podcast(conn, 123)
    assert Map.has_key?(conn.assigns, :podcast)
    assert conn.assigns.podcast.id == 123
  end

  test "returns 403s", %{conn: conn} do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, account_id: 888})
    conn = call_auth_podcast(conn, 123)
    refute Map.has_key?(conn.assigns, :podcast)
    assert conn.status == 403
    assert conn.halted == true
    assert conn.resp_body =~ ~r/you do not have access/i
  end

  test "returns 404s", %{conn: conn} do
    conn = call_auth_podcast(conn, 456)
    refute Map.has_key?(conn.assigns, :podcast)
    assert conn.status == 404
    assert conn.halted == true
    assert conn.resp_body =~ ~r/not found/i
  end

  test "handles non integer ids", %{conn: conn} do
    conn = call_auth_podcast(conn, "abc")
    refute Map.has_key?(conn.assigns, :podcast)
    assert conn.status == 404
    assert conn.halted == true
    assert conn.resp_body =~ ~r/not found/i
  end

  defp call_auth_podcast(conn, id) do
    conn
    |> Castle.Plugs.Auth.call([])
    |> Map.put(:params, %{"id" => id})
    |> Castle.Plugs.AuthPodcast.call([])
  end
end
