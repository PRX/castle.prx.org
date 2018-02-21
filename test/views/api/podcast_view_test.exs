defmodule Castle.API.PodcastViewTest do
  use Castle.ConnCase, async: true

  import CastleWeb.API.PodcastView

  test "index.json", %{conn: conn} do
    doc = render("index.json", %{conn: conn, podcasts: test_podcasts(), meta: %{}})
    embedded = doc[:"_embedded"][:"prx:items"]

    assert doc.count == 2
    assert doc.total == 2
    assert length(embedded) == 2
    assert hd(embedded).id == "foo"
    assert hd(embedded).downloads.total == 999
  end

  test "show.json", %{conn: conn} do
    trends = %{today: 1, yesterday: 2, this7: 3, last7: 4}
    doc = render("show.json", %{conn: conn, podcast: "foo", total: 999, trends: trends, meta: %{}})
    assert doc.id == "foo"
    assert doc.downloads.total == 999
    assert doc.downloads.today == 1
    assert doc.downloads.yesterday == 2
    assert doc.downloads.this7days == 3
    assert doc.downloads.previous7days == 4
  end

  defp test_podcasts do
    [{"foo", 999}, {"bar", 999}]
  end
end
