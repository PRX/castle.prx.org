defmodule Castle.API.PodcastControllerTest do
  use Castle.ConnCase, async: false

  import Mock

  describe "index/2" do
    test "responds with a list of podcasts", %{conn: conn} do
      with_mock Castle.Rollup, fake_datas() do
        resp = conn |> get(api_podcast_path(conn, :index)) |> json_response(200)
        assert resp["count"] == 2
        assert resp["total"] == 2
        assert length(resp["_embedded"]["prx:items"]) == 2
      end
    end
  end

  describe "show/2" do
    test "responds with a single podcast", %{conn: conn} do
      with_mock Castle.Rollup, fake_data() do
        resp = conn |> get(api_podcast_path(conn, :show, 999)) |> json_response(200)
        assert resp["id"] == 999
        assert "_links" in Map.keys(resp)
      end
    end

    test "renders 404s", %{conn: conn} do
      with_mock Castle.Rollup, fake_empty() do
        resp = conn |> get(api_podcast_path(conn, :show, 999))
        assert resp.status == 404
      end
    end
  end

  defp fake_data do
    [podcast_total: fn(_id) -> 999 end, podcast_trends: fn(_id) -> %{} end]
  end

  defp fake_empty do
    [podcast_total: fn(_id) -> nil end, podcast_trends: fn(_id) -> %{} end]
  end

  defp fake_datas do
    [podcasts: fn() -> [{"foo", 123}, {"bar", 456}] end]
  end
end
