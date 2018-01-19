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
    doc = render("show.json", %{conn: conn, podcast: test_podcast("foo"), meta: %{}})
    assert doc.id == "foo"
    assert doc.downloads.total == 999
  end

  defp test_podcasts do
    Enum.map(["foo", "bar"], &test_podcast/1)
  end

  defp test_podcast(id) do
    %{feeder_podcast: id, feeder_episodes: ["guid1", "guid2"], count: 999}
  end
end
