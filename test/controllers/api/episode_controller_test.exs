defmodule Castle.API.EpisodeControllerTest do
  use Castle.ConnCase, async: false

  alias Castle.Rollup.Data.Totals, as: Totals

  import Mock

  describe "index/2" do
    test "responds with a list of episodes", %{conn: conn} do
      with_mock Totals, fake_datas() do
        resp = conn |> get(api_episode_path(conn, :index)) |> json_response(200)
        assert resp["count"] == 2
        assert resp["total"] == 2
        assert length(resp["_embedded"]["prx:items"]) == 2
      end
    end
  end

  describe "show/2" do
    test "responds with a single episode", %{conn: conn} do
      with_mock Totals, fake_data() do
        resp = conn |> get(api_episode_path(conn, :show, "foo")) |> json_response(200)
        assert resp["guid"] == "foo"
        assert "_links" in Map.keys(resp)
      end
    end

    test "renders 404s", %{conn: conn} do
      with_mock Totals, fake_empty() do
        resp = conn |> get(api_episode_path(conn, :show, "foo"))
        assert resp.status == 404
      end
    end
  end

  defp fake_data do
    [episode: fn(id) -> episode_json(id) end]
  end

  defp fake_empty do
    [episode: fn(_id) -> nil end]
  end

  defp fake_datas do
    [episodes: fn() -> [episode_json("foo"), episode_json("bar")] end]
  end

  defp episode_json(guid) do
    %{feeder_episode: guid, feeder_podcast: 123, count: 999}
  end
end
