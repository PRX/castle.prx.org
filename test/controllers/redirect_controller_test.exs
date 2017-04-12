defmodule Castle.RedirectControllerTest do
  use Castle.ConnCase, async: true

  describe "index/2" do
    test "redirects to the api", %{conn: conn} do
      location = conn |> get(redirect_path(conn, :index)) |> redirected_to(302)
      assert location == "/api/v1"
    end
  end
end
