defmodule Castle.API.ImpressionControllerTest do
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
      resp = conn |> get_podcast(123, from: "2017-04-01", group: "city", grouplimit: "blah") |> response(400)
      assert resp =~ ~r/grouplimit is not an integer/i
      resp = conn |> get_podcast(123, from: "2017-04-01", group: "city", grouplimit: 11) |> json_response(200)
      assert resp["id"] == 123
    end
  end

  test "responds with impressions for a podcast", %{conn: conn} do
    with_mock BigQuery, fake_data() do
      resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-02", interval: "15m") |> json_response(200)
      assert resp["id"] == 123
      assert resp["interval"] == "15MIN"
      assert length(resp["impressions"]) == 20
      assert hd(resp["impressions"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with grouped impressions for a podcast", %{conn: conn} do
    with_mock BigQuery, fake_groups() do
      resp = conn |> get_podcast(123, from: "2017-04-01", to: "2017-04-02", interval: "15m", group: "city") |> json_response(200)
      assert resp["id"] == 123
      assert resp["interval"] == "15MIN"
      assert length(resp["groups"]) == 1
      assert hd(resp["groups"]) == "foo"
      assert length(resp["impressions"]) == 20
      assert hd(resp["impressions"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with impressions for an episode", %{conn: conn} do
    with_mock BigQuery, fake_data() do
      resp = conn |> get_episode("hello", from: "2017-04-01", to: "2017-04-02", interval: "15m") |> json_response(200)
      assert resp["guid"] == "hello"
      assert resp["interval"] == "15MIN"
      assert length(resp["impressions"]) == 20
      assert hd(resp["impressions"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  test "responds with grouped impressions for an episode", %{conn: conn} do
    with_mock BigQuery, fake_groups() do
      resp = conn |> get_episode("hello", from: "2017-04-01", to: "2017-04-02", interval: "15m", group: "country") |> json_response(200)
      assert resp["guid"] == "hello"
      assert resp["interval"] == "15MIN"
      assert length(resp["groups"]) == 1
      assert hd(resp["groups"]) == "foo"
      assert length(resp["impressions"]) == 20
      assert hd(resp["impressions"]) == ["2017-03-22T00:00:00Z", 0]
    end
  end

  defp get_podcast(conn, id, query_params \\ %{}) do
    conn |> get(api_podcast_impression_path(conn, :index, id, query_params))
  end

  defp get_episode(conn, guid, query_params) do
    conn |> get(api_episode_impression_path(conn, :index, guid, query_params))
  end

  defp fake_data do
    [
      podcast_impressions: &impressions/1,
      episode_impressions: &impressions/1,
    ]
  end

  defp fake_groups do
    [
      podcast_impressions: &group_impressions/3,
      episode_impressions: &group_impressions/3,
    ]
  end

  defp group_impressions(_id, _interval, _group) do
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T00:00:00Z")
    {Enum.map(0..19, &group_impression(&1, start)), %{meta: "data"}}
  end

  defp group_impression(num, start_dtim) do
    %{count: num, time: Timex.shift(start_dtim, minutes: num * 900), display: "foo", rank: 1}
  end

  defp impressions(_interval) do
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T00:00:00Z")
    {Enum.map(0..19, &impression(&1, start)), %{meta: "data"}}
  end

  defp impression(num, start_dtim) do
    {Timex.shift(start_dtim, minutes: num * 900), %{123 => num, "hello" => num}}
  end
end
