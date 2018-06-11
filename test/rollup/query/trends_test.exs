defmodule Castle.RollupQueryTrendsTest do
  use Castle.DataCase, async: false
  use Castle.TimeHelpers

  import Castle.Rollup.Query.Trends

  @id 1234
  @guid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

  setup do
    now = get_dtim("2018-04-24T13:22:09")
    upsert_hourly("2018-04-24T14:00:00", 1)
    upsert_hourly("2018-04-24T13:00:00", 2)
    upsert_hourly("2018-04-24T01:00:00", 3)
    upsert_hourly("2018-04-23T22:00:00", 4)
    upsert_hourly("2018-04-22T09:00:00", 5)
    upsert_hourly("2018-04-17T08:00:00", 6)
    upsert_hourly("2018-04-11T08:00:00", 7)
    upsert_hourly("2018-04-10T08:00:00", 8)
    [now: now]
  end

  test "gets podcast trends", %{now: now} do
    trends = podcast_trends(@id, now)
    assert trends.total == 35
    assert trends.today == 5
    assert trends.yesterday == 4
    assert trends.this7days == 14
    assert trends.previous7days == 13
  end

  test "gets episode trends", %{now: now} do
    trends = episode_trends(@guid, now)
    assert trends.total == 35
    assert trends.today == 5
    assert trends.yesterday == 4
    assert trends.this7days == 14
    assert trends.previous7days == 13
  end

  test "gets lack of trends", %{now: now} do
    trends = podcast_trends(2345, now)
    assert trends.total == 0
    assert trends.today == 0
    assert trends.yesterday == 0
    assert trends.this7days == 0
    assert trends.previous7days == 0
  end

  test "adds cached counts to trends data", %{now: now} do
    trends = podcast_trends(@id, now)
    cached = [
      %{count: 100, time: get_dtim("2018-04-25T23:00:00")},
      %{count: 2, time: get_dtim("2018-04-24T08:00:00")},
      %{count: 3, time: get_dtim("2018-04-23T23:00:00")},
      %{count: 4, time: get_dtim("2018-04-11T14:00:00")},
      %{count: 100, time: get_dtim("2018-04-08T14:00:00")},
    ]
    combined_trends = add_cached(trends, cached, now)
    assert combined_trends.total == trends.total + 209
    assert combined_trends.today == trends.today + 2
    assert combined_trends.yesterday == trends.yesterday + 3
    assert combined_trends.this7days == trends.this7days + 5
    assert combined_trends.previous7days == trends.previous7days + 4
  end

  test "adds monthly downloads to trends data", %{now: now} do
    upsert_monthly(~D[2018-01-01], 100)

    upsert_log("monthly_downloads", ~D[2018-01-01], false)
    trends1 = podcast_trends(@id, now)
    upsert_log("monthly_downloads", ~D[2018-01-01], true)
    trends2 = podcast_trends(@id, now)

    assert trends2.total == trends1.total + 100
  end

  test "ignores hourly data already covered by monthly", %{now: now} do
    upsert_monthly(~D[2018-04-01], 100)
    upsert_log("monthly_downloads", ~D[2018-04-01], true)
    trends = podcast_trends(@id, now)
    assert trends.total == 100
  end

  defp upsert_hourly(dtim_str, count) do
    %{podcast_id: @id, episode_id: @guid, dtim: get_dtim(dtim_str), count: count}
    |> Castle.HourlyDownload.upsert()
  end

  defp upsert_monthly(date, count) do
    [%{podcast_id: @id, episode_id: @guid, month: date, count: count}]
    |> Castle.MonthlyDownload.upsert_all()
  end

  defp upsert_log(tbl, date, complete) do
    %Castle.RollupLog{table_name: tbl, date: date, complete: complete}
    |> Castle.RollupLog.upsert!()
  end
end
