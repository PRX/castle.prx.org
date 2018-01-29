defmodule Castle.PlugsIntervalRollupsTest do
  use Castle.ConnCase, async: true

  test "gets rollup values from the bucket", %{conn: conn} do
    assert parse_name(conn, BigQuery.TimestampRollups.Hourly) == "HOUR"
    assert parse_name(conn, BigQuery.TimestampRollups.Daily) == "HOUR"
    assert parse_name(conn, BigQuery.TimestampRollups.Weekly) == "DAY"
    assert parse_name(conn, BigQuery.TimestampRollups.Monthly) == "DAY"
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

  defp call_parse(conn, bucket) do
    conn
    |> set_bucket(bucket)
    |> Castle.Plugs.Interval.Rollups.parse()
  end

  defp set_bucket(conn, nil), do: conn
  defp set_bucket(conn, bucket), do: Plug.Conn.assign(conn, :interval, %{bucket: bucket})
end
