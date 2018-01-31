defmodule Castle.PlugsIntervalRollupsTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  @hourly BigQuery.TimestampRollups.Hourly
  @daily BigQuery.TimestampRollups.Daily
  @weekly BigQuery.TimestampRollups.Weekly
  @monthly BigQuery.TimestampRollups.Monthly

  test "gets rollup values from the bucket", %{conn: conn} do
    assert parse_name(conn, @hourly) == "HOUR"
    assert parse_name(conn, @daily) == "HOUR"
    assert parse_name(conn, @weekly) == "DAY"
    assert parse_name(conn, @monthly) == "DAY"
  end

  test "rolls up by days when not offset from start-of-day", %{conn: conn} do
    assert parse_name(conn, @daily, "2018-01-04T00:00:00Z", "2018-01-08T00:00:00Z") == "DAY"
    assert parse_name(conn, @daily, "2018-01-04T00:00:01Z", "2018-01-08T00:00:00Z") == "DAY"
    assert parse_name(conn, @daily, "2018-01-04T00:00:00Z", "2018-01-07T23:59:59Z") == "DAY"
    assert parse_name(conn, @daily, "2018-01-04T01:00:00Z", "2018-01-08T00:00:00Z") == "HOUR"
    assert parse_name(conn, @daily, "2018-01-03T23:59:59Z", "2018-01-08T00:00:00Z") == "HOUR"
    assert parse_name(conn, @daily, "2018-01-04T00:00:00Z", "2018-01-08T00:00:01Z") == "HOUR"
  end

  test "requires a bucket be defined", %{conn: conn} do
    assert_raise FunctionClauseError, fn ->
      call_parse(conn, nil)
    end
  end

  test "requires a known bucket name", %{conn: conn} do
    assert_raise CaseClauseError, fn ->
      call_parse(conn, %{name: "foo"})
    end
  end

  defp parse_name(conn, bucket) do
    {:ok, rollup} = call_parse(conn, bucket)
    rollup.name
  end
  defp parse_name(conn, bucket, from, to) do
    {:ok, rollup} = call_parse(conn, bucket, from, to)
    rollup.name
  end

  defp call_parse(conn, bucket, from \\ "2018-01-04T00:00:00Z", to \\ "2018-01-08T12:00:00Z") do
    conn
    |> set_bucket(bucket, from, to)
    |> Castle.Plugs.Interval.Rollups.parse()
  end

  defp set_bucket(conn, nil, _from, _to), do: conn
  defp set_bucket(conn, bucket, from, to) do
    Plug.Conn.assign(conn, :interval, %{
      from: get_dtim(from),
      to: get_dtim(to),
      bucket: bucket,
    })
  end
end
