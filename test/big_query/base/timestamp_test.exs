defmodule Castle.BigQueryBaseTimestampTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Base.Timestamp

  @fifteen %{rollup: BigQuery.TimestampRollups.QuarterHourly}
  @weekly %{rollup: BigQuery.TimestampRollups.Weekly}

  test "groups by a param" do
    sql = timestamp_sql("the_table", @fifteen, "feeder_podcast")
    assert sql =~ ~r/FROM the_table/
    assert sql =~ ~r/GROUP BY time, feeder_podcast/
    assert sql =~ ~r/SELECT time, feeder_podcast, count/
  end

  test "uses a modulo based rollup" do
    sql = timestamp_sql("the_table", @fifteen, "feeder_podcast")
    assert sql =~ ~r/MOD\(UNIX_SECONDS\(timestamp\), 900/
  end

  test "uses a truncation rollup" do
    sql = timestamp_sql("the_table", @weekly, "feeder_podcast")
    assert sql =~ ~r/TIMESTAMP_TRUNC\(timestamp, WEEK/
  end

  test "sets params" do
    start = get_dtim("2017-03-22T21:54:52Z")
    finish = get_dtim("2017-03-28T04:12:00Z")
    interval = %BigQuery.Interval{from: start, to: finish, rollup: BigQuery.TimestampRollups.QuarterHourly}
    params = timestamp_params(interval)

    assert_time params.from_dtim, "2017-03-22T21:54:52Z"
    assert_time params.to_dtim, "2017-03-28T04:12:00Z"
    assert_time params.pstart, "2017-03-22T00:00:00Z"
    assert_time params.pend, "2017-03-28T23:59:59.999999Z"
  end

  test "groups results" do
    start = get_dtim("2017-03-28T04:00:00Z")
    finish = get_dtim("2017-03-28T11:00:00Z")
    interval = %BigQuery.Interval{from: start, to: finish, rollup: BigQuery.TimestampRollups.Hourly}
    raw = [
      %{time: get_dtim("2017-03-28T05:00:00Z"), feeder_podcast: 123, count: 11},
      %{time: get_dtim("2017-03-28T06:00:00Z"), feeder_podcast: 456, count: 22},
      %{time: get_dtim("2017-03-28T06:00:00Z"), feeder_podcast: 123, count: 33},
      %{time: get_dtim("2017-03-28T07:00:00Z"), feeder_podcast: 123, count: 44},
      %{time: get_dtim("2017-03-28T09:00:00Z"), feeder_podcast: 456, count: 55},
      %{time: get_dtim("2017-03-28T09:00:00Z"), feeder_podcast: 789, count: 66},
    ]
    {data, _meta} = group({raw, %{}}, interval, "feeder_podcast")

    assert length(data) == 7
    assert_time Enum.at(data, 0), "2017-03-28T04:00:00Z"
    assert_time Enum.at(data, 1), "2017-03-28T05:00:00Z"
    assert_time Enum.at(data, 2), "2017-03-28T06:00:00Z"
    assert_time Enum.at(data, 3), "2017-03-28T07:00:00Z"
    assert_time Enum.at(data, 4), "2017-03-28T08:00:00Z"
    assert_time Enum.at(data, 5), "2017-03-28T09:00:00Z"
    assert_time Enum.at(data, 6), "2017-03-28T10:00:00Z"

    assert get_counts(data, 0) == %{}
    assert get_counts(data, 1) == %{123 => 11}
    assert get_counts(data, 2) == %{123 => 33, 456 => 22}
    assert get_counts(data, 3) == %{123 => 44}
    assert get_counts(data, 4) == %{}
    assert get_counts(data, 5) == %{456 => 55, 789 => 66}
    assert get_counts(data, 6) == %{}
  end

  defp get_dtim(dtim_str) do
    {:ok, dtim, _} = DateTime.from_iso8601(dtim_str)
    dtim
  end

  defp assert_time({dtim, _map}, expected_str), do: assert_time(dtim, expected_str)
  defp assert_time(dtim, expected_str) do
    {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
    assert formatted == expected_str
  end

  defp get_counts(data, at) do
    {_time, counts} = Enum.at(data, at)
    counts
  end
end
