defmodule Castle.API.RankControllerTest do
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
    do_insert(~D[2017-04-01], "US", "MN", 1)
    do_insert(~D[2017-04-02], "US", "CO", 2)
    do_insert(~D[2017-04-04], "GB", "UK", 3)
    do_insert(~D[2017-04-05], "GB", "UK", 4)
    do_insert(~D[2017-04-05], "US", "MN", 5)
    []
  end

  test "requires query params", %{conn: conn} do
    resp = conn |> get_podcast(123) |> response(400)
    assert resp =~ ~r/missing required/i
    resp = conn |> get_podcast(123, from: "2017-04-01") |> response(400)
    assert resp =~ ~r/must set a group/i
    resp = conn |> get_podcast(123, from: "2017-04-01", group: "geosubdiv") |> json_response(200)
    assert resp["id"] == 123
  end

  test "validates group params", %{conn: conn} do
    resp = conn |> get_podcast(123, from: "2017-04-01", group: "blah") |> response(400)
    assert resp =~ ~r/bad group param/i
    resp = conn |> get_podcast(123, from: "2017-04-01", group: "geometro") |> json_response(200)
    assert resp["id"] == 123
  end

  test "responds with totals for a podcast", %{conn: conn} do
    resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-06", group: "geosubdiv", limit: 2) |> json_response(200)
    assert resp["id"] == 123
    assert resp["interval"]["from"] == "2017-04-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-04-06T00:00:00Z"
    assert resp["group"]["name"] == "geosubdiv"
    assert resp["group"]["limit"] == 2
    assert resp["ranks"] == ["GB-UK", "US-MN", nil]
    assert length(resp["downloads"]) == 5
    assert Enum.at(resp["downloads"], 0) == ["2017-04-01T00:00:00Z", [0, 1, 0]]
    assert Enum.at(resp["downloads"], 1) == ["2017-04-02T00:00:00Z", [0, 0, 2]]
    assert Enum.at(resp["downloads"], 2) == ["2017-04-03T00:00:00Z", [0, 0, 0]]
    assert Enum.at(resp["downloads"], 3) == ["2017-04-04T00:00:00Z", [3, 0, 0]]
    assert Enum.at(resp["downloads"], 4) == ["2017-04-05T00:00:00Z", [4, 5, 0]]
  end

  test "responds with downloads for an episode", %{conn: conn} do
    resp = conn |> get_episode(@guid, from: "2017-04-02T11:12:13", to: "2017-04-05T15:16:17", group: "geosubdiv") |> json_response(200)
    assert resp["id"] == @guid
    assert resp["interval"]["from"] == "2017-04-02T00:00:00Z"
    assert resp["interval"]["to"] == "2017-04-06T00:00:00Z"
    assert resp["group"]["name"] == "geosubdiv"
    assert resp["group"]["limit"] == 10
    assert resp["ranks"] == ["GB-UK", "US-MN", "US-CO", nil]
    assert length(resp["downloads"]) == 4
    assert Enum.at(resp["downloads"], 0) == ["2017-04-02T00:00:00Z", [0, 0, 2, 0]]
    assert Enum.at(resp["downloads"], 1) == ["2017-04-03T00:00:00Z", [0, 0, 0, 0]]
    assert Enum.at(resp["downloads"], 2) == ["2017-04-04T00:00:00Z", [3, 0, 0, 0]]
    assert Enum.at(resp["downloads"], 3) == ["2017-04-05T00:00:00Z", [4, 5, 0, 0]]
  end

  test "renders podcast 404s", %{conn: conn} do
    resp = conn |> get(api_podcast_download_path(conn, :index, 999, %{from: "2018-04-01", group: "geosubdiv"}))
    assert resp.status == 404
  end

  test "renders episode 404s", %{conn: conn} do
    resp = conn |> get(api_episode_download_path(conn, :index, "999", %{from: "2018-04-01", group: "geosubdiv"}))
    assert resp.status == 404
  end

  test "renders podcast 403s", %{conn: conn} do
    resp = conn |> get(api_podcast_download_path(conn, :index, "456", %{from: "2018-04-01", group: "geosubdiv"}))
    assert resp.status == 403
  end

  test "renders episode 403s", %{conn: conn} do
    resp = conn |> get(api_episode_download_path(conn, :index, @guid2, %{from: "2018-04-01", group: "geosubdiv"}))
    assert resp.status == 403
  end

  defp get_podcast(conn, id, query_params \\ %{}) do
    conn |> get(api_podcast_rank_path(conn, :index, id, query_params))
  end

  defp get_episode(conn, id, query_params) do
    conn |> get(api_episode_rank_path(conn, :index, id, query_params))
  end

  defp do_insert(date, country, subdiv, count) do
    Castle.DailyGeoSubdiv.upsert %{
      podcast_id: @id,
      episode_id: @guid,
      country_iso_code: country,
      subdivision_1_iso_code: subdiv,
      day: date,
      count: count
    }
  end
end
