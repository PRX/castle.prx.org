defmodule Castle.API.TotalViewTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.TotalView

  test "total.json" do
    time = get_dtim("2017-04-09T21:45:00Z")

    ranks = [
      %{group: "AB", count: 10},
      %{group: "CD", count: 9},
      %{group: "EF", count: 8},
      %{group: "GH", count: 7}
    ]

    intv = %Castle.Interval{from: time, to: time, bucket: Castle.Bucket.Daily}

    group = %Castle.Grouping{
      name: "somegroup",
      ranks: nil,
      totals: nil,
      labels: Castle.Label.GeoCountry,
      limit: 99
    }

    doc = render("total.json", %{id: 123, interval: intv, group: group, ranks: ranks})

    assert doc.id == 123
    assert doc.interval.from == "2017-04-09T21:45:00Z"
    assert doc.interval.to == "2017-04-09T21:45:00Z"
    assert doc.group.name == "somegroup"
    assert length(doc.ranks) == 4
    assert Enum.at(doc.ranks, 0) == %{code: "AB", label: "Unknown", count: 10}
    assert Enum.at(doc.ranks, 1) == %{code: "CD", label: "Congo", count: 9}
    assert Enum.at(doc.ranks, 2) == %{code: "EF", label: "Unknown", count: 8}
    assert Enum.at(doc.ranks, 3) == %{code: "GH", label: "Ghana", count: 7}
  end
end
