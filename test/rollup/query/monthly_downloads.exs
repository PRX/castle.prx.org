defmodule Castle.RollupMonthlyDownloadsTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  alias Castle.Rollup.Query.MonthlyDownloads, as: MonthlyDownloads

  @id1 1234
  @id2 5678
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  @guid3 "cccccccc-cccc-cccc-cccc-cccccccccccc"

  setup do
    now = get_dtim("2018-04-24T13:22:09")
    do_insert(@id1, @guid1, "2018-05-01T14:00:00", 1)
    do_insert(@id1, @guid1, "2018-04-24T13:00:00", 2)
    do_insert(@id1, @guid1, "2018-04-24T01:00:00", 3)
    do_insert(@id1, @guid1, "2018-04-23T22:00:00", 4)
    do_insert(@id1, @guid2, "2018-04-22T09:00:00", 5)
    do_insert(@id2, @guid3, "2018-04-17T08:00:00", 6)
    do_insert(@id1, @guid1, "2018-04-11T08:00:00", 7)
    do_insert(@id1, @guid1, "2018-03-29T08:00:00", 8)
    [now: now]
  end

  test "gets an entire month of data", %{now: now} do
    month = MonthlyDownloads.all(now)
    assert length(month) == 3
    assert Enum.at(month, 0).podcast_id == @id1
    assert Enum.at(month, 0).episode_id == @guid1
    assert Enum.at(month, 0).count == 16
    assert Enum.at(month, 0).month == ~D[2018-04-01]
    assert Enum.at(month, 1).podcast_id == @id1
    assert Enum.at(month, 1).episode_id == @guid2
    assert Enum.at(month, 1).count == 5
    assert Enum.at(month, 1).month == ~D[2018-04-01]
    assert Enum.at(month, 2).podcast_id == @id2
    assert Enum.at(month, 2).episode_id == @guid3
    assert Enum.at(month, 2).count == 6
    assert Enum.at(month, 2).month == ~D[2018-04-01]
  end

  defp do_insert(id, guid, dtim_str, count) do
    Castle.HourlyDownload.upsert %{
      podcast_id: id,
      episode_id: guid,
      dtim: get_dtim(dtim_str),
      count: count
    }
  end
end
