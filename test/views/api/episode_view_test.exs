defmodule Castle.API.EpisodeViewTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.EpisodeView

  test "index.json", %{conn: conn} do
    time = get_dtim("2017-04-09T21:45:00Z")
    eps = [
      %{id: "guid1", podcast_id: 1, title: "one", subtitle: "one", total_downloads: 1, published_at: time, image_url: nil},
      %{id: "guid2", podcast_id: 1, title: "two", subtitle: "two", total_downloads: 2, published_at: time, image_url: nil},
    ]
    paging = %{page: 1, per: 2, total: 2}
    doc = render("index.json", %{conn: conn, episodes: eps, paging: paging})

    assert doc.count == 2
    assert doc.total == 2
    assert doc[:_links][:first].href == "/api/v1/episodes?per=2"
    assert doc[:_links][:last].href == "/api/v1/episodes?per=2"

    embedded = doc[:_embedded][:"prx:items"]
    assert length(embedded) == 2
    assert hd(embedded).id == "guid1"
    assert hd(embedded).title == "one"
    assert hd(embedded).subtitle == "one"
    assert hd(embedded).publishedAt == "2017-04-09T21:45:00Z"
  end

  test "show.json", %{conn: conn} do
    time = get_dtim("2017-04-09T21:45:00Z")
    trends = %{today: 1, yesterday: 2, this7days: 3, previous7days: 4, total: 999}
    ep = %{id: "guid1", podcast_id: 1, title: "one", subtitle: "one", published_at: time, image_url: nil}
    doc = render("show.json", %{conn: conn, episode: ep, trends: trends})
    assert doc.id == "guid1"
    assert doc.title == "one"
    assert doc.subtitle == "one"
    assert doc.publishedAt == "2017-04-09T21:45:00Z"
    assert doc.downloads.total == 999
    assert doc.downloads.today == 1
    assert doc.downloads.yesterday == 2
    assert doc.downloads.this7days == 3
    assert doc.downloads.previous7days == 4
    assert doc[:_links][:"prx:podcast"].href == "/api/v1/podcasts/1"
  end
end
