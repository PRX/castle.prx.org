defmodule Porter.API.RootControllerTest do
  use Porter.ConnCase, async: true

  describe "index/2" do
    test "responds with the root doc", %{conn: conn} do
      resp = conn |> get(api_root_path(conn, :index)) |> json_response(200)

      assert "version" in Map.keys(resp)
      assert resp["version"] == "v1"
      assert "_links" in Map.keys(resp)
      assert "prx:podcasts" in Map.keys(resp["_links"])
    end
  end
end
