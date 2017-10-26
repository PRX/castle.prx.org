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
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T21:54:52Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-03-28T04:12:00Z")
    interval = %BigQuery.Interval{from: start, to: finish, rollup: 900}
    params = timestamp_params(interval)

    assert Timex.to_unix(params.from_dtim) == 1490219692
    assert Timex.to_unix(params.to_dtim) == 1490674320
    assert Timex.to_unix(params.pstart) == 1490140800
    assert Timex.to_unix(params.pend) == 1490745599
  end
end
