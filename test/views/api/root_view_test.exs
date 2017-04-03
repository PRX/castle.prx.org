defmodule Porter.API.RootViewTest do
  use Porter.ConnCase, async: true

  test "index.json", %{conn: conn} do
    doc = Porter.API.RootView.render("index.json", %{conn: conn})
    links = doc[:_links]

    assert doc.version == "v1"
    assert links.self.href =~ ~r/api\/v1/
    assert links.profile.href =~ ~r/meta\.prx\.org/
  end
end
