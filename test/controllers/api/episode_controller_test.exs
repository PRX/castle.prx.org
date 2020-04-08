defmodule Castle.API.EpisodeControllerTest do
  use Castle.ConnCase, async: false
  import Castle.Repo, only: [insert!: 1]

  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  @guid3 "cccccccc-cccc-cccc-cccc-cccccccccccc"
  @guid4 "dddddddd-dddd-dddd-dddd-dddddddddddd"
  @past Timex.shift(Timex.now(), hours: -1) |> DateTime.truncate(:second)

  setup do
    System.put_env("DEV_AUTH", "999")
    insert!(%Castle.Podcast{id: 123, title: "one", account_id: 999})
    insert!(%Castle.Podcast{id: 456, title: "two", account_id: 888})
    insert!(%Castle.Episode{id: @guid1, podcast_id: 123, title: "one", published_at: @past})
    insert!(%Castle.Episode{id: @guid2, podcast_id: 123, title: "two", published_at: @past})
    insert!(%Castle.Episode{id: @guid3, podcast_id: 456, title: "three", published_at: @past})
    []
  end

  describe "index/2" do
    test "per single podcast id, responds with a list of episodes", %{conn: conn} do
      resp = conn |> get(api_podcast_episode_path(conn, :index, 123)) |> json_response(200)
      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == @guid1
      assert resp["_links"]["first"]["href"] == "/api/v1/podcasts/123/episodes"
    end

    test "per single podcast id, can search episodes", %{conn: conn} do
      resp =
        conn
        |> get(api_podcast_episode_path(conn, :index, 123, search: "two"))
        |> json_response(200)

      assert resp["count"] == 1
      assert resp["total"] == 1
      assert length(resp["_embedded"]["prx:items"]) == 1
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == @guid2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "two"
      assert resp["_links"]["first"]["href"] == "/api/v1/podcasts/123/episodes?search=two"
    end

    test "responds with a list of episodes", %{conn: conn} do
      resp = conn |> get(api_episode_path(conn, :index)) |> json_response(200)
      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == @guid1
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "one"
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["id"] == @guid2
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["title"] == "two"
      assert resp["_links"]["first"]["href"] == "/api/v1/episodes"
    end

    test "allows searching with search, page and per params", %{conn: conn} do
      insert!(%Castle.Episode{
        id: @guid4,
        podcast_id: 123,
        title: "one another test",
        published_at: @past
      })

      # search for all podcasts with "one" as title
      resp =
        conn
        |> get(api_episode_path(conn, :index), %{search: "one", page: 1, per: 2})
        |> json_response(200)

      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2

      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == @guid1
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "one"

      assert Enum.at(resp["_embedded"]["prx:items"], 1)["id"] == @guid4
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["title"] == "one another test"

      assert resp["_links"]["first"]["href"] == "/api/v1/episodes?per=2&search=one"
    end

    test "responds with a list of episodes for a podcast", %{conn: conn} do
      resp = conn |> get(api_podcast_episode_path(conn, :index, 123)) |> json_response(200)
      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == @guid1
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "one"
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["id"] == @guid2
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["title"] == "two"
      assert resp["_links"]["first"]["href"] == "/api/v1/podcasts/123/episodes"
    end

    test "renders 404s", %{conn: conn} do
      resp = conn |> get(api_podcast_episode_path(conn, :index, 9999))
      assert resp.status == 404
    end

    test "renders 403s", %{conn: conn} do
      resp = conn |> get(api_podcast_episode_path(conn, :index, 456))
      assert resp.status == 403
    end
  end

  describe "show/2" do
    test "responds with a single episode", %{conn: conn} do
      resp = conn |> get(api_episode_path(conn, :show, @guid1)) |> json_response(200)
      assert resp["id"] == @guid1
      assert resp["title"] == "one"
      assert "_links" in Map.keys(resp)
    end

    test "renders 404s", %{conn: conn} do
      resp = conn |> get(api_episode_path(conn, :show, "foo"))
      assert resp.status == 404
    end

    test "renders 403s", %{conn: conn} do
      resp = conn |> get(api_episode_path(conn, :show, @guid3))
      assert resp.status == 403
    end
  end
end
