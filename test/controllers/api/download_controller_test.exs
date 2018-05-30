defmodule Castle.API.DownloadControllerTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  @id 123
  @guid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @id2 456
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  setup do
    System.put_env("DEV_AUTH", "999")
    Castle.Repo.insert!(%Castle.Podcast{id: @id, title: "pod1", account_id: 999})
    Castle.Repo.insert!(%Castle.Podcast{id: @id2, title: "pod2", account_id: 888})
    Castle.Repo.insert!(%Castle.Episode{id: @guid, podcast_id: @id, title: "ep1"})
    Castle.Repo.insert!(%Castle.Episode{id: @guid2, podcast_id: @id2, title: "ep2"})
    do_insert("2017-03-27T12:00:00", 1)
    do_insert("2017-04-02T14:00:00", 2)
    do_insert("2017-04-04T10:00:00", 3)
    do_insert("2017-04-05T04:00:00", 4)
    []
  end

  test "requires query params", %{conn: conn} do
    resp = conn |> get_podcast(123) |> response(400)
    assert resp =~ ~r/missing required/i
    resp = conn |> get_podcast(123, from: "blah") |> response(400)
    assert resp =~ ~r/bad from param/i
    resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-05") |> json_response(200)
    assert resp["id"] == 123
  end

  test "validates group params", %{conn: conn} do
    resp = conn |> get_podcast(123, from: "2017-04-01", group: "blah") |> response(400)
    assert resp =~ ~r/bad group param/i
    resp = conn |> get_podcast(123, from: "2017-04-01", group: "city") |> json_response(200)
    assert resp["id"] == 123
  end

  test "responds with downloads for a podcast", %{conn: conn} do
    resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-05", interval: "1d") |> json_response(200)
    assert resp["id"] == 123
    assert resp["interval"]["name"] == "DAY"
    assert resp["interval"]["from"] == "2017-04-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-04-05T00:00:00Z"
    assert length(resp["downloads"]) == 4
    assert Enum.at(resp["downloads"], 0) == ["2017-04-01T00:00:00Z", 0]
    assert Enum.at(resp["downloads"], 1) == ["2017-04-02T00:00:00Z", 2]
    assert Enum.at(resp["downloads"], 2) == ["2017-04-03T00:00:00Z", 0]
    assert Enum.at(resp["downloads"], 3) == ["2017-04-04T00:00:00Z", 3]
  end

  test "responds with downloads for an episode", %{conn: conn} do
    resp = conn |> get_episode(@guid, from: "2017-04-02T11:12:13", to: "2017-04-02T15:16:17", interval: "HOUR") |> json_response(200)
    assert resp["id"] == @guid
    assert resp["interval"]["name"] == "HOUR"
    assert resp["interval"]["from"] == "2017-04-02T11:00:00Z"
    assert resp["interval"]["to"] == "2017-04-02T16:00:00Z"
    assert length(resp["downloads"]) == 5
    assert Enum.at(resp["downloads"], 0) == ["2017-04-02T11:00:00Z", 0]
    assert Enum.at(resp["downloads"], 1) == ["2017-04-02T12:00:00Z", 0]
    assert Enum.at(resp["downloads"], 2) == ["2017-04-02T13:00:00Z", 0]
    assert Enum.at(resp["downloads"], 3) == ["2017-04-02T14:00:00Z", 2]
    assert Enum.at(resp["downloads"], 4) == ["2017-04-02T15:00:00Z", 0]
  end

  test "renders podcast 404s", %{conn: conn} do
    resp = conn |> get(api_podcast_download_path(conn, :index, 999, %{from: "2018-04-01"}))
    assert resp.status == 404
  end

  test "renders episode 404s", %{conn: conn} do
    resp = conn |> get(api_episode_download_path(conn, :index, "999", %{from: "2018-04-01"}))
    assert resp.status == 404
  end

  test "renders podcast 403s", %{conn: conn} do
    resp = conn |> get(api_podcast_download_path(conn, :index, "456", %{from: "2018-04-01"}))
    assert resp.status == 403
  end

  test "renders episode 403s", %{conn: conn} do
    resp = conn |> get(api_episode_download_path(conn, :index, @guid2, %{from: "2018-04-01"}))
    assert resp.status == 403
  end

  defp get_podcast(conn, id, query_params \\ %{}) do
    conn |> get(api_podcast_download_path(conn, :index, id, query_params))
  end

  defp get_episode(conn, id, query_params) do
    conn |> get(api_episode_download_path(conn, :index, id, query_params))
  end

  defp do_insert(dtim_str, count) do
    Castle.HourlyDownload.upsert %{
      podcast_id: @id,
      episode_id: @guid,
      dtim: get_dtim(dtim_str),
      count: count
    }
  end
end
