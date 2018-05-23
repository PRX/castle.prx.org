defmodule Castle.API.DownloadViewTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.DownloadView

  test "download.json" do
    time = get_dtim("2017-04-09T21:45:00Z")
    downs = [%{time: time, count: 98}, %{time: time, count: 76}, %{time: time, count: 54}]
    intv = %Castle.Interval{from: time, to: time, bucket: Castle.Bucket.Daily}
    doc = render("download.json", %{id: 123, interval: intv, downloads: downs})

    assert doc.id == 123
    assert doc.interval.from == "2017-04-09T21:45:00Z"
    assert doc.interval.to == "2017-04-09T21:45:00Z"
    assert doc.interval.name == "DAY"
    assert length(doc.downloads) == 3
    assert hd(doc.downloads) == ["2017-04-09T21:45:00Z", 98]
  end
end
