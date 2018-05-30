defmodule Castle.API.EpisodeControllerTest do
  use Castle.ConnCase, async: false

  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  @guid3 "cccccccc-cccc-cccc-cccc-cccccccccccc"

  setup do
    System.put_env("DEV_AUTH", "999")
    Castle.Repo.insert!(%Castle.Podcast{id: 123, title: "one", account_id: 999})
    Castle.Repo.insert!(%Castle.Podcast{id: 456, title: "two", account_id: 888})
    Castle.Repo.insert!(%Castle.Episode{id: @guid1, podcast_id: 123, title: "one"})
    Castle.Repo.insert!(%Castle.Episode{id: @guid2, podcast_id: 123, title: "two"})
    Castle.Repo.insert!(%Castle.Episode{id: @guid3, podcast_id: 456, title: "three"})
    []
  end

  describe "index/2" do
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
