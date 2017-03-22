defmodule Porter.DemoControllerTest do
  use Porter.ConnCase, async: true

  describe "index/2" do
    test "responds with bigquery counts", %{conn: conn} do
      resp = conn |> get(demo_path(conn, :index)) |> json_response(200)

      assert "programs" in Map.keys(resp)
      assert length(resp["programs"]) > 4
      assert "name" in Map.keys(hd resp["programs"])
      assert "impressions" in Map.keys(hd resp["programs"])
    end
  end
end
