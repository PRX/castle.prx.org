defmodule Castle.API.EpisodeViewTest do
  use Castle.ConnCase, async: true

  import CastleWeb.API.EpisodeView

  test "index.json", %{conn: conn} do
    doc = render("index.json", %{conn: conn, episodes: test_episodes(), meta: %{}})
    embedded = doc[:"_embedded"][:"prx:items"]

    assert doc.count == 2
    assert doc.total == 2
    assert length(embedded) == 2
    assert hd(embedded).guid == "foo"
    assert hd(embedded).downloads.total == 999
  end

  test "show.json", %{conn: conn} do
    trends = %{today: 1, this7: 2, last7: 3}
    doc = render("show.json", %{conn: conn, episode: test_episode("foo"), trends: trends, meta: %{}})
    assert doc.guid == "foo"
    assert doc.downloads.total == 999
    assert doc.downloads.today == 1
    assert doc.downloads.yesterday == 0
    assert doc.downloads.this7days == 2
    assert doc.downloads.previous7days == 3
    assert doc._links["prx:podcast"].href =~ ~r/podcasts\/123/
  end

  defp test_episodes do
    Enum.map(["foo", "bar"], &test_episode/1)
  end

  defp test_episode(guid) do
    %{feeder_episode: guid, feeder_podcast: 123, count: 999}
  end
end
