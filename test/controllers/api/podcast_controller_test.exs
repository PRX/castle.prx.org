defmodule Porter.API.PodcastControllerTest do
  use Porter.ConnCase, async: true

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
      with_mock BigQuery, fake_programs() do
        resp = conn |> get(api_podcast_path(conn, :show, "foo")) |> json_response(200)
        assert resp["name"] == "foo"
        assert "_links" in Map.keys(resp)
      end
    end
  end

  defp fake_programs do
    [
      programs: fn() -> Enum.map(["foo", "bar"], fn(p) -> program(p) end) end,
      program: fn(id) -> program(id) end,
    ]
  end

  defp program(name) do
    %{program: name, past1: 10, past12: 20, past24: 30, past48: 40}
  end
end
