defmodule Castle.RollupMonthlyDownloadsTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.MonthlyDownloads

  @id1 1234
  @id2 5678
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  @guid3 "cccccccc-cccc-cccc-cccc-cccccccccccc"

  setup do
    now = get_dtim("2018-04-24T13:22:09")
    upsert_hourly(@id1, @guid1, "2018-05-01T14:00:00", 1)
    upsert_hourly(@id1, @guid1, "2018-04-24T13:00:00", 2)
    upsert_hourly(@id1, @guid1, "2018-04-24T01:00:00", 3)
    upsert_hourly(@id1, @guid1, "2018-04-23T22:00:00", 4)
    upsert_hourly(@id1, @guid2, "2018-04-22T09:00:00", 5)
    upsert_hourly(@id2, @guid3, "2018-04-17T08:00:00", 6)
    upsert_hourly(@id1, @guid1, "2018-04-11T08:00:00", 7)
    upsert_hourly(@id1, @guid1, "2018-03-29T08:00:00", 8)
    [now: now]
  end

  test "gets an entire month of data", %{now: now} do
    month = from_hourly(now)
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

  test "gets podcast totals until a date" do
    beginning = Castle.RollupLog.beginning_of_time
    upsert_monthly(@id1, @guid1, ~D[2018-01-01], 10)
    upsert_monthly(@id1, @guid1, ~D[2018-04-01], 11)

    assert podcast_total_until(@id1) == {0, beginning}
    assert podcast_total_until(@id2) == {0, beginning}
    upsert_log(~D[2018-01-01], false)
    assert podcast_total_until(@id1) == {0, beginning}
    assert podcast_total_until(@id2) == {0, beginning}
    upsert_log(~D[2018-01-01], true)
    assert podcast_total_until(@id1) == {10, ~D[2018-02-01]}
    assert podcast_total_until(@id2) == {0, ~D[2018-02-01]}
    upsert_log(~D[2018-04-01], true)
    assert podcast_total_until(@id1) == {21, ~D[2018-05-01]}
    assert podcast_total_until(@id2) == {0, ~D[2018-05-01]}
  end

  test "gets episode totals until a date" do
    beginning = Castle.RollupLog.beginning_of_time
    upsert_monthly(@id1, @guid1, ~D[2018-01-01], 10)
    upsert_monthly(@id1, @guid1, ~D[2018-04-01], 11)

    assert episode_total_until(@guid1) == {0, beginning}
    assert episode_total_until(@guid2) == {0, beginning}
    upsert_log(~D[2018-01-01], false)
    assert episode_total_until(@guid1) == {0, beginning}
    assert episode_total_until(@guid2) == {0, beginning}
    upsert_log(~D[2018-01-01], true)
    assert episode_total_until(@guid1) == {10, ~D[2018-02-01]}
    assert episode_total_until(@guid2) == {0, ~D[2018-02-01]}
    upsert_log(~D[2018-04-01], true)
    assert episode_total_until(@guid1) == {21, ~D[2018-05-01]}
    assert episode_total_until(@guid2) == {0, ~D[2018-05-01]}
  end

  defp upsert_hourly(id, guid, dtim_str, count) do
    Castle.HourlyDownload.upsert %{
      podcast_id: id,
      episode_id: guid,
      dtim: get_dtim(dtim_str),
      count: count
    }
  end

  defp upsert_monthly(id, guid, date, count) do
    [%{podcast_id: id, episode_id: guid, month: date, count: count}]
    |> Castle.MonthlyDownload.upsert_all()
  end

  defp upsert_log(date, complete) do
    %Castle.RollupLog{table_name: "monthly_downloads", date: date, complete: complete}
    |> Castle.RollupLog.upsert!()
  end
end
