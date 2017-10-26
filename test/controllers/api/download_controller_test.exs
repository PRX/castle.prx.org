defmodule Castle.API.DownloadControllerTest do
  use Castle.ConnCase, async: false

  import Mock

  test "requires query params", %{conn: conn} do
    with_mock BigQuery, fake_data() do
      resp = conn |> get_podcast(123) |> response(400)
      assert resp =~ ~r/missing required/i
      resp = conn |> get_podcast(123, from: "blah") |> response(400)
      assert resp =~ ~r/bad from param/i
      resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-02") |> json_response(200)
      assert resp["id"] == 123
    end
  end

  test "validates group params", %{conn: conn} do
    with_mock BigQuery, fake_groups() do
      resp = conn |> get_podcast(123, from: "2017-04-01", group: "blah") |> response(400)
      assert resp =~ ~r/bad group param/i
      resp = conn |> get_podcast(123, from: "2017-04-01", group: "city") |> json_response(200)
      assert resp["id"] == 123
    end
  end

  test "responds with downloads for a podcast", %{conn: conn} do
    with_mock BigQuery, fake_data() do
      resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-02", interval: "15m") |> json_response(200)
      assert resp["id"] == 123
      assert resp["interval"] == "15MIN"
      assert length(resp["downloads"]) == 20
      assert hd(resp["downloads"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with grouped downloads for a podcast", %{conn: conn} do
    with_mock BigQuery, fake_groups() do
      resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-02", interval: "15m", group: "city") |> json_response(200)
      assert resp["id"] == 123
      assert resp["interval"] == "15MIN"
      assert length(resp["groups"]) == 1
      assert hd(resp["groups"]) == "foo"
      assert length(resp["downloads"]) == 20
      assert hd(resp["downloads"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with downloads for an episode", %{conn: conn} do
    with_mock BigQuery, fake_data() do
      resp = conn |> get_episode("hello", from: "2017-04-01", to: "2017-04-02", interval: "15m") |> json_response(200)
      assert resp["guid"] == "hello"
      assert resp["interval"] == "15MIN"
      assert length(resp["downloads"]) == 20
      assert hd(resp["downloads"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with grouped downloads for an episode", %{conn: conn} do
    with_mock BigQuery, fake_groups() do
      resp = conn |> get_episode("hello", from: "2017-04-01", to: "2017-04-02", interval: "15m", group: "country") |> json_response(200)
      assert resp["guid"] == "hello"
      assert resp["interval"] == "15MIN"
      assert length(resp["groups"]) == 1
      assert hd(resp["groups"]) == "foo"
      assert length(resp["downloads"]) == 20
      assert hd(resp["downloads"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  defp get_podcast(conn, id, query_params \\ %{}) do
    conn |> get(api_podcast_download_path(conn, :index, id, query_params))
  end

  defp get_episode(conn, guid, query_params) do
    conn |> get(api_episode_download_path(conn, :index, guid, query_params))
  end

  defp fake_data do
    [
      podcast_downloads: &downloads/1,
      episode_downloads: &downloads/1,
    ]
  end

  defp fake_groups do
    [
      podcast_downloads: &group_downloads/3,
      episode_downloads: &group_downloads/3,
    ]
  end

  defp group_downloads(_id, _interval, _group) do
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T00:00:00Z")
    {Enum.map(0..19, &group_download(&1, start)), %{meta: "data"}}
  end

  defp group_download(num, start_dtim) do
    %{count: num, time: Timex.shift(start_dtim, minutes: num * 900), display: "foo", rank: 1}
  end

  defp downloads(_interval) do
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T00:00:00Z")
    {Enum.map(0..19, &download(&1, start)), %{meta: "data"}}
  end

  defp download(num, start_dtim) do
    {Timex.shift(start_dtim, minutes: num * 900), %{123 => num, "hello" => num}}
  end
end
