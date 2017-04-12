defmodule Castle.API.EpisodeViewTest do
  use Castle.ConnCase, async: true

  import Castle.API.EpisodeView

  test "index.json", %{conn: conn} do
    doc = render("index.json", %{conn: conn, episodes: test_episodes(), meta: %{}})
    embedded = doc[:"_embedded"][:"prx:items"]

    assert doc.count == 2
    assert doc.total == 2
    assert length(embedded) == 2
    assert hd(embedded).guid == "foo"
    assert hd(embedded).downloads.past1 == 10
  end

  test "show.json", %{conn: conn} do
    doc = render("show.json", %{conn: conn, episode: test_episode("foo"), meta: %{}})
    assert doc.guid == "foo"
    assert doc.downloads.past1 == 10
    assert doc.downloads.past12 == 20
    assert doc.downloads.past24 == 30
    assert doc.downloads.past48 == 40
    assert doc.impressions.past1 == 0
    assert doc.impressions.past12 == 0
    assert doc.impressions.past24 == 7
    assert doc.impressions.past48 == 9
  end

  defp test_episodes do
    Enum.map(["foo", "bar"], &test_episode/1)
  end

  defp test_episode(guid) do
    %{feeder_episode: guid,
      downloads_past1: 10, downloads_past12: 20, downloads_past24: 30, downloads_past48: 40,
      impressions_past1: nil, impressions_past12: 0, impressions_past24: 7, impressions_past48: 9}
  end
end
