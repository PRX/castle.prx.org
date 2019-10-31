defmodule Castle.API.ListenerControllerTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  @id 123
  @id2 456

  setup do
    System.put_env("DEV_AUTH", "999")
    Castle.Repo.insert!(%Castle.Podcast{id: @id, title: "pod1", account_id: 999})
    Castle.Repo.insert!(%Castle.Podcast{id: @id2, title: "pod2", account_id: 888})

    Castle.MonthlyUnique.upsert_all([
      %{
        podcast_id: @id,
        month: ~D[2017-03-01],
        count: 1
      },
      %{
        podcast_id: @id,
        month: ~D[2017-04-01],
        count: 2
      },
      %{
        podcast_id: @id,
        month: ~D[2017-05-01],
        count: 3
      }
    ])

    Castle.WeeklyUnique.upsert_all([
      %{
        podcast_id: @id,
        week: ~D[2017-03-01],
        count: 1
      },
      %{
        podcast_id: @id,
        week: ~D[2017-03-02],
        count: 2
      },
      %{
        podcast_id: @id,
        week: ~D[2017-03-03],
        count: 3
      }
    ])

    Castle.LastWeekUnique.upsert_all([
      %{
        podcast_id: @id,
        week: ~D[2017-03-06],
        count: 1
      },
      %{
        podcast_id: @id,
        week: ~D[2017-03-13],
        count: 2
      },
      %{
        podcast_id: @id,
        week: ~D[2017-03-20],
        count: 3
      }
    ])

    Castle.Last28Unique.upsert_all([
      %{
        podcast_id: @id,
        last_28: ~D[2017-03-01],
        count: 2
      },
      %{
        podcast_id: @id,
        last_28: ~D[2017-03-29],
        count: 3
      }
    ])

    :ok
  end

  test "requires query params", %{conn: conn} do
    resp = conn |> get_podcast(123) |> response(400)
    assert resp =~ ~r/Missing required param: from/i

    resp = conn |> get_podcast(123, %{interval: "MONTH", from: "blah"}) |> response(400)
    assert resp =~ ~r/bad from param/i

    resp = conn |> get_podcast(123, interval: "MONTH", from: "2017-04-01", to: "2017-04-05") |> json_response(200)
    assert resp["id"] == 123
  end

  test "responds with listeners for a rolling last week", %{conn: conn} do
    resp =
      conn
      |> get_podcast(123, from: "2017-03-01", to: "2017-03-31", interval: "LAST_WEEK")
      |> json_response(200)

    assert resp["id"] == 123
    assert resp["interval"]["name"] == "DAY"
    assert resp["interval"]["from"] == "2017-03-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-03-31T00:00:00Z"
    assert length(resp["listeners"]) == 3
    assert Enum.at(resp["listeners"], 0) == ["2017-03-06T00:00:00Z", 1]
    assert Enum.at(resp["listeners"], 1) == ["2017-03-13T00:00:00Z", 2]
    assert Enum.at(resp["listeners"], 2) == ["2017-03-20T00:00:00Z", 3]
  end

  test "responds with listeners for a rolling last 28", %{conn: conn} do
    resp =
      conn
      |> get_podcast(123, from: "2017-03-01", to: "2017-03-31", interval: "LAST_28")
      |> json_response(200)

    assert resp["id"] == 123
    assert resp["interval"]["name"] == "DAY"
    assert resp["interval"]["from"] == "2017-03-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-03-31T00:00:00Z"
    assert length(resp["listeners"]) == 2
    assert Enum.at(resp["listeners"], 0) == ["2017-03-01T00:00:00Z", 2]
    assert Enum.at(resp["listeners"], 1) == ["2017-03-29T00:00:00Z", 3]
  end

  test "responds with listeners for a refreshed monthly", %{conn: conn} do
    resp =
      conn
      |> get_podcast(123, from: "2017-03-01", to: "2017-06-01", interval: "MONTH")
      |> json_response(200)

    assert resp["id"] == 123
    assert resp["interval"]["name"] == "MONTH"
    assert resp["interval"]["from"] == "2017-03-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-06-01T00:00:00Z"
    assert length(resp["listeners"]) == 3
    assert Enum.at(resp["listeners"], 0) == ["2017-03-01T00:00:00Z", 1]
    assert Enum.at(resp["listeners"], 1) == ["2017-04-01T00:00:00Z", 2]
    assert Enum.at(resp["listeners"], 2) == ["2017-05-01T00:00:00Z", 3]
  end

  test "utilizes the interval plug for bounding to/from", %{conn: conn} do
    resp =
      conn
      |> get_podcast(123, from: "2017-03-02", to: "2017-05-31", interval: "MONTH")
      |> json_response(200)

    assert resp["interval"]["from"] == "2017-03-01T00:00:00Z"
    assert resp["interval"]["to"] == "2017-06-01T00:00:00Z"
  end

  test "utilizes daily bounding for 'last' rolling windows to/from", %{conn: conn} do
    resp =
      conn
      |> get_podcast(123, from: "2017-03-02", to: "2017-05-31", interval: "LAST_WEEK")
      |> json_response(200)

    assert resp["interval"]["from"] == "2017-03-02T00:00:00Z"
    assert resp["interval"]["to"] == "2017-05-31T00:00:00Z"
  end

  test "renders podcast 404s", %{conn: conn} do
    resp = conn |> get(api_podcast_listener_path(conn, :index, 999, %{from: "2018-04-01"}))
    assert resp.status == 404
  end

  test "renders podcast 403s", %{conn: conn} do
    resp = conn |> get(api_podcast_listener_path(conn, :index, "456", %{from: "2018-04-01"}))
    assert resp.status == 403
  end

  defp get_podcast(conn, id, query_params \\ %{}) do
    conn |> get(api_podcast_listener_path(conn, :index, id, query_params))
  end
end
