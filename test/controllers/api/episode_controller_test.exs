defmodule Castle.API.EpisodeControllerTest do
  use Castle.ConnCase, async: false

  import Mock

  describe "index/2" do
    test "responds with a list of episodes", %{conn: conn} do
      with_mock Castle.Rollup, fake_datas() do
        resp = conn |> get(api_episode_path(conn, :index)) |> json_response(200)
        assert resp["count"] == 2
        assert resp["total"] == 2
        assert length(resp["_embedded"]["prx:items"]) == 2
      end
    end
  end

  describe "show/2" do
    test "responds with a single episode", %{conn: conn} do
      with_mock Castle.Rollup, fake_data() do
        resp = conn |> get(api_episode_path(conn, :show, "foo")) |> json_response(200)
        assert resp["guid"] == "foo"
        assert "_links" in Map.keys(resp)
      end
    end

    test "renders 404s", %{conn: conn} do
      with_mock Castle.Rollup, fake_empty() do
        resp = conn |> get(api_episode_path(conn, :show, "foo"))
        assert resp.status == 404
      end
    end
  end

  defp fake_data do
    [episode_total: fn(_guid) -> 999 end, episode_trends: fn(_guid) -> %{} end]
  end

  defp fake_empty do
    [episode_total: fn(_guid) -> nil end, episode_trends: fn(_guid) -> %{} end]
  end

  defp fake_datas do
    [episodes: fn() -> [{"foo", 123}, {"bar", 456}] end]
  end
end
