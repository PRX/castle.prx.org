defmodule Castle.API.PodcastControllerTest do
  use Castle.ConnCase, async: false

  setup do
    System.put_env("DEV_AUTH", "999")
    Castle.Repo.insert!(%Castle.Podcast{id: 123, title: "one", account_id: 999})
    Castle.Repo.insert!(%Castle.Podcast{id: 456, title: "two", account_id: 999})
    Castle.Repo.insert!(%Castle.Podcast{id: 789, title: "three", account_id: 888})
    []
  end

  describe "index/2" do
    test "responds with a list of podcasts", %{conn: conn} do
      resp = conn |> get(api_podcast_path(conn, :index)) |> json_response(200)
      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == 123
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "one"
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["id"] == 456
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["title"] == "two"
      assert resp["_links"]["first"]["href"] == "/api/v1/podcasts"
    end
  end

  describe "show/2" do
    test "responds with a single podcast", %{conn: conn} do
      resp = conn |> get(api_podcast_path(conn, :show, 123)) |> json_response(200)
      assert resp["id"] == 123
      assert resp["title"] == "one"
      assert "_links" in Map.keys(resp)
    end

    test "renders 404s", %{conn: conn} do
      resp = conn |> get(api_podcast_path(conn, :show, "999"))
      assert resp.status == 404
    end

    test "renders 403s", %{conn: conn} do
      resp = conn |> get(api_podcast_path(conn, :show, "789"))
      assert resp.status == 403
    end
  end
end
