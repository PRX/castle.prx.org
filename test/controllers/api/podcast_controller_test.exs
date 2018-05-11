defmodule Castle.API.PodcastControllerTest do
  use Castle.ConnCase, async: true

  setup do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, title: "one"})
    Castle.Repo.insert!(%Castle.Podcast{id: 456, title: "two"})
    []
  end

  describe "index/2" do
    test "responds with a list of podcasts", %{conn: conn} do
      resp = conn |> get(api_podcast_path(conn, :index)) |> json_response(200)
      assert resp["count"] == 2
      assert resp["total"] == 2
      assert length(resp["_embedded"]["prx:items"]) == 2
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["id"] == 456
      assert Enum.at(resp["_embedded"]["prx:items"], 0)["title"] == "two"
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["id"] == 123
      assert Enum.at(resp["_embedded"]["prx:items"], 1)["title"] == "one"
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
  end
end
