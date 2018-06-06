defmodule Castle.API.RankViewTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.RankView

  test "rank.json" do
    time = get_dtim("2017-04-09T21:45:00Z")
    ranks = ["AB", "CD", nil]
    downs = [
      %{time: time, counts: [98, 1, 0], ranks: ranks},
      %{time: time, counts: [76, 1, 0], ranks: ranks},
      %{time: time, counts: [54, 1, 0], ranks: ranks},
    ]
    intv = %Castle.Interval{from: time, to: time, bucket: Castle.Bucket.Daily}
    group = %Castle.Grouping{name: "somegroup", ranks: nil, totals: nil, limit: 99}
    doc = render("rank.json", %{id: 123, interval: intv, group: group, ranks: ranks, downloads: downs})

    assert doc.id == 123
    assert doc.interval.from == "2017-04-09T21:45:00Z"
    assert doc.interval.to == "2017-04-09T21:45:00Z"
    assert doc.interval.name == "DAY"
    assert doc.group.name == "somegroup"
    assert doc.group.limit == 99
    assert doc.ranks == ["AB", "CD", nil]
    assert length(doc.downloads) == 3
    assert Enum.at(doc.downloads, 0) == ["2017-04-09T21:45:00Z", [98, 1, 0]]
    assert Enum.at(doc.downloads, 1) == ["2017-04-09T21:45:00Z", [76, 1, 0]]
    assert Enum.at(doc.downloads, 2) == ["2017-04-09T21:45:00Z", [54, 1, 0]]
  end
end
