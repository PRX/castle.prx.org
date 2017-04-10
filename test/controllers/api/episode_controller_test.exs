defmodule Porter.API.EpisodeControllerTest do
  use Porter.ConnCase, async: false

  import Mock

  describe "index/2" do
    test "responds with a list of episodes", %{conn: conn} do
      with_mock BigQuery, fake_datas() do
        resp = conn |> get(api_episode_path(conn, :index)) |> json_response(200)
        assert resp["count"] == 2
        assert resp["total"] == 2
        assert length(resp["_embedded"]["prx:items"]) == 2
      end
    end
  end

  describe "show/2" do
    test "responds with a single episode", %{conn: conn} do
      with_mock BigQuery, fake_data() do
        resp = conn |> get(api_episode_path(conn, :show, "foo")) |> json_response(200)
        assert resp["guid"] == "foo"
        assert "_links" in Map.keys(resp)
      end
    end
  end

  defp fake_data do
    [episode: fn(id) -> {episode_json(id), %{meta: "data"}} end]
  end

  defp fake_datas do
    [episodes: fn() -> {[episode_json("foo"), episode_json("bar")], %{meta: "data"}} end]
  end

  defp episode_json(guid) do
    %{feeder_episode: guid,
      downloads_past1: 10, downloads_past12: 20, downloads_past24: 30, downloads_past48: 40,
      impressions_past1: 1, impressions_past12: 2, impressions_past24: 3, impressions_past48: 4}
  end
end
