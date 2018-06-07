defmodule Castle.PlugsAuthEpisodeTest do
  use Castle.ConnCase, async: true

  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  setup do
    System.put_env("DEV_AUTH", "999")
    []
  end

  test "authorizes episodes", %{conn: conn} do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, account_id: 999})
    Castle.Repo.insert!(%Castle.Episode{id: @guid1, podcast_id: 123})
    conn = call_auth_episode(conn, @guid1)
    assert Map.has_key?(conn.assigns, :episode)
    assert conn.assigns.episode.id == @guid1
  end

  test "returns 403s", %{conn: conn} do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, account_id: 888})
    Castle.Repo.insert!(%Castle.Episode{id: @guid1, podcast_id: 123})
    conn = call_auth_episode(conn, @guid1)
    refute Map.has_key?(conn.assigns, :episode)
    assert conn.status == 403
    assert conn.halted == true
    assert conn.resp_body =~ ~r/you do not have access/i
  end

  test "returns 404s", %{conn: conn} do
    conn = call_auth_episode(conn, @guid2)
    refute Map.has_key?(conn.assigns, :episode)
    assert conn.status == 404
    assert conn.halted == true
    assert conn.resp_body =~ ~r/not found/i
  end

  test "handles non uuids", %{conn: conn} do
    conn = call_auth_episode(conn, 123)
    refute Map.has_key?(conn.assigns, :episode)
    assert conn.status == 404
    assert conn.halted == true
    assert conn.resp_body =~ ~r/not found/i
  end

  defp call_auth_episode(conn, id) do
    conn
    |> Castle.Plugs.Auth.call([])
    |> Map.put(:params, %{"id" => id})
    |> Castle.Plugs.AuthEpisode.call([])
  end
end
