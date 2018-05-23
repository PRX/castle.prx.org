defmodule Castle.PlugsIntervalBucketTest do
  use Castle.ConnCase, async: true

  @default_from "2017-04-01T14:04:00Z"
  @default_to "2017-04-01T14:05:00Z"

  test "sets interval bucket values", %{conn: conn} do
    assert parse_name(conn, "1h") == "HOUR"
    assert parse_name(conn, "1d") == "DAY"
    assert parse_name(conn, "1w") == "WEEK"
    assert parse_name(conn, "1M") == "MONTH"
  end

  test "validates interval values", %{conn: conn} do
    {:error, err} = call_parse(conn, "9a")
    assert err =~ ~r/bad interval param/i
  end

  test "guesses interval from the time window", %{conn: conn} do
    assert parse_name(conn, nil, "2017-04-01T00:01:00Z", "2017-04-01T00:02:00Z") == "HOUR"
    assert parse_name(conn, nil, "2017-04-01T00:01:00Z", "2017-04-01T12:00:00Z") == "HOUR"
    assert parse_name(conn, nil, "2017-04-01T00:01:00Z", "2017-04-06T00:00:00Z") == "DAY"
    assert parse_name(conn, nil, "2017-04-01T00:01:00Z", "2017-09-06T00:00:00Z") == "WEEK"
    assert parse_name(conn, nil, "2017-04-01T00:01:00Z", "2018-04-06T00:00:00Z") == "MONTH"
  end

  test "validates the intervals per time window", %{conn: conn} do
    {:error, err} = call_parse(conn, "1h", "2017-03-01T00:00:00Z", "2017-05-01T00:00:00Z")
    assert err =~ ~r/time window too large/i
  end

  defp parse_name(conn, interval, from_str \\ @default_from, to_str \\ @default_to) do
    {:ok, bucket} = call_parse(conn, interval, from_str, to_str)
    bucket.name
  end

  defp call_parse(conn, interval, from_str, to_str) do
    {:ok, time_from} = Timex.parse(from_str, "{ISO:Extended}")
    {:ok, time_to} = Timex.parse(to_str, "{ISO:Extended}")
    conn
    |> set_interval(interval)
    |> Plug.Conn.assign(:interval, %{from: time_from, to: time_to})
    |> Castle.Plugs.Interval.Bucket.parse()
  end
  defp call_parse(conn, interval), do: call_parse(conn, interval, @default_from, @default_to)

  defp set_interval(conn, nil), do: conn
  defp set_interval(conn, interval) do
    conn |> Map.merge(%{params: %{"interval" => interval}})
  end
end
