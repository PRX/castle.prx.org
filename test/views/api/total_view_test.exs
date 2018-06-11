defmodule Castle.API.TotalViewTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.TotalView

  test "total.json" do
    time = get_dtim("2017-04-09T21:45:00Z")
    downs = [
      %{group: "AB", count: 10},
      %{group: "CD", count: 9},
      %{group: "EF", count: 8},
      %{group: "GH", count: 7},
    ]
    intv = %Castle.Interval{from: time, to: time, bucket: Castle.Bucket.Daily}
    group = %Castle.Grouping{name: "somegroup", ranks: nil, totals: nil, limit: 99}
    doc = render("total.json", %{id: 123, interval: intv, group: group, downloads: downs})

    assert doc.id == 123
    assert doc.interval.from == "2017-04-09T21:45:00Z"
    assert doc.interval.to == "2017-04-09T21:45:00Z"
    assert doc.group.name == "somegroup"
    assert length(doc.downloads) == 4
    assert Enum.at(doc.downloads, 0) == ["AB", 10]
    assert Enum.at(doc.downloads, 1) == ["CD", 9]
    assert Enum.at(doc.downloads, 2) == ["EF", 8]
    assert Enum.at(doc.downloads, 3) == ["GH", 7]
  end
end
