defmodule Castle.API.DownloadViewTest do
  use Castle.ConnCase, async: true

  import Castle.API.DownloadView

  test "podcast.json" do
    {:ok, time, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    imps = [%{time: time, count: 98}, %{time: time, count: 76}, %{time: time, count: 54}]
    doc = render("podcast.json", %{id: 123, interval: 150, downloads: imps, meta: %{}})

    assert doc.id == 123
    assert doc.interval == 150
    assert length(doc.downloads) == 3
    assert hd(doc.downloads) == [time, 98]
  end

  test "episode.json" do
    {:ok, time, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    imps = [%{time: time, count: 98}, %{time: time, count: 76}, %{time: time, count: 54}]
    doc = render("episode.json", %{guid: "456", interval: 150, downloads: imps, meta: %{}})

    assert doc.guid == "456"
    assert doc.interval == 150
    assert length(doc.downloads) == 3
    assert hd(doc.downloads) == [time, 98]
  end
end