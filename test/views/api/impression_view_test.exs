defmodule Castle.API.ImpressionViewTest do
  use Castle.ConnCase, async: true

  import Castle.API.ImpressionView

  test "podcast.json" do
    {:ok, time, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    imps = [%{time: time, count: 98}, %{time: time, count: 76}, %{time: time, count: 54}]
    doc = render("podcast.json", %{id: 123, interval: 150, impressions: imps, meta: %{}})

    assert doc.id == 123
    assert doc.interval == 150
    assert length(doc.impressions) == 3
    assert hd(doc.impressions) == [time, 98]
  end

  test "podcast-group.json" do
    {:ok, time1, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    {:ok, time2, _} = DateTime.from_iso8601("2017-04-09T22:00:00Z")
    imps = [
      %{time: time1, count: 11, rank: 1, display: "one"},
      %{time: time2, count: 22, rank: 2, display: "two"},
      %{time: time2, count: 23, rank: 3, display: "three"},
      %{time: time1, count: 13, rank: 3, display: "three"},
      %{time: time2, count: 21, rank: 1, display: "one"},
      %{time: time1, count: 12, rank: 2, display: "two"},
    ]
    doc = render("podcast-group.json", %{id: 123, interval: 150, impressions: imps, meta: %{}})

    assert doc.id == 123
    assert doc.interval == 150
    assert doc.groups == ["one", "two", "three"]
    assert length(doc.impressions) == 2
    assert Enum.at(doc.impressions, 0) == [time1, 11, 12, 13]
    assert Enum.at(doc.impressions, 1) == [time2, 21, 22, 23]
  end

  test "episode.json" do
    {:ok, time, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    imps = [%{time: time, count: 98}, %{time: time, count: 76}, %{time: time, count: 54}]
    doc = render("episode.json", %{guid: "456", interval: 150, impressions: imps, meta: %{}})

    assert doc.guid == "456"
    assert doc.interval == 150
    assert length(doc.impressions) == 3
    assert hd(doc.impressions) == [time, 98]
  end

  test "episode-group.json" do
    {:ok, time, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    imps = [%{time: time, count: 98, rank: 1, display: "foo"}, %{time: time, count: 76, rank: 2, display: "bar"}]
    doc = render("episode-group.json", %{guid: "456", interval: 150, impressions: imps, meta: %{}})

    assert doc.guid == "456"
    assert doc.interval == 150
    assert doc.groups == ["foo", "bar"]
    assert length(doc.impressions) == 1
    assert hd(doc.impressions) == [time, 98, 76]
  end
end
