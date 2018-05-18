defmodule Castle.API.PodcastViewTest do
  use Castle.ConnCase, async: true

  import CastleWeb.API.PodcastView

  test "index.json", %{conn: conn} do
    pods = [
      %{id: 1, title: "one", subtitle: "one", total_downloads: 1, image_url: nil},
      %{id: 2, title: "two", subtitle: "two", total_downloads: 2, image_url: nil},
    ]
    paging = %{page: 1, per: 2, total: 2}
    doc = render("index.json", %{conn: conn, podcasts: pods, paging: paging})

    assert doc.count == 2
    assert doc.total == 2
    assert doc[:"_links"][:"first"].href == "/api/v1/podcasts?per=2"
    assert doc[:"_links"][:"last"].href == "/api/v1/podcasts?per=2"

    embedded = doc[:"_embedded"][:"prx:items"]
    assert length(embedded) == 2
    assert hd(embedded).id == 1
    assert hd(embedded).title == "one"
    assert hd(embedded).subtitle == "one"
  end

  test "show.json", %{conn: conn} do
    trends = %{today: 1, yesterday: 2, this7days: 3, previous7days: 4, total: 999}
    pod = %{id: 1, title: "one", subtitle: "one", image_url: nil}
    doc = render("show.json", %{conn: conn, podcast: pod, trends: trends})
    assert doc.id == 1
    assert doc.title == "one"
    assert doc.subtitle == "one"
    assert doc.downloads.total == 999
    assert doc.downloads.today == 1
    assert doc.downloads.yesterday == 2
    assert doc.downloads.this7days == 3
    assert doc.downloads.previous7days == 4
  end
end
