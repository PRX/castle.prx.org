defmodule Porter.PageControllerTest do
  use Porter.ConnCase, async: true

  describe "index/2" do
    test "redirects to the api", %{conn: conn} do
      location = conn |> get("/") |> redirected_to(302)
      assert location == "/api/v1"
    end
  end
end
