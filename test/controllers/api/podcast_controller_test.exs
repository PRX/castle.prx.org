defmodule Porter.API.PodcastControllerTest do
  use Porter.ConnCase, async: false

  import Mock

  describe "index/2" do
    test "responds with a list of podcasts", %{conn: conn} do
      with_mock BigQuery, fake_programs() do
        resp = conn |> get(api_podcast_path(conn, :index)) |> json_response(200)
        assert resp["count"] == 2
        assert resp["total"] == 2
        assert length(resp["_embedded"]["prx:items"]) == 2
      end
    end
  end

  describe "show/2" do
    test "responds with a single podcast", %{conn: conn} do
      with_mock BigQuery, fake_program() do
        resp = conn |> get(api_podcast_path(conn, :show, "foo")) |> json_response(200)
        assert resp["name"] == "foo"
        assert "_links" in Map.keys(resp)
      end
    end
  end

  defp fake_program do
    [program: fn(id) -> {program(id), %{meta: "data"}} end]
  end

  defp fake_programs do
    [programs: fn() -> {[program("foo"), program("bar")], %{meta: "data"}} end]
  end

  defp program(name) do
    %{program: name,
      downloads_past1: 10, downloads_past12: 20, downloads_past24: 30, downloads_past48: 40,
      impressions_past1: 1, impressions_past12: 2, impressions_past24: 3, impressions_past48: 4}
  end
end
