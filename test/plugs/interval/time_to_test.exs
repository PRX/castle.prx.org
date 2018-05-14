defmodule Castle.PlugsIntervalTimeToTest do
  use Castle.ConnCase, async: true

  test "sets a default as the next day", %{conn: conn} do
    {:ok, time_to} = Castle.Plugs.Interval.TimeTo.parse(conn)
    tomorrow = Timex.now |> Timex.beginning_of_day |> Timex.shift(days: 1)
    assert time_to == tomorrow
  end

  test "parses query timestamps", %{conn: conn} do
    {:ok, time_to} = call_time_to(conn, "2017-04-01T14:04:11Z")
    assert Timex.to_unix(time_to) == 1491055451
  end

  test "rounds up query dates", %{conn: conn} do
    {:ok, time_to} = call_time_to(conn, "2017-04-01")
    assert Timex.to_unix(time_to) == 1491091199
  end

  test "does not round up full timestamps", %{conn: conn} do
    {:ok, time_to} = call_time_to(conn, "2017-04-01T00:00:00Z")
    assert Timex.to_unix(time_to) == 1491004800
  end

  test "converts to utc", %{conn: conn} do
    {:ok, time_to} = call_time_to(conn, "2017-04-01T08:04:11-06:00 Etc/GMT+6")
    {:ok, offset} = Timex.format(time_to, "{Z}")
    assert Timex.to_unix(time_to) == 1491055451
    assert offset == "+0000"
  end

  test "handles invalid params", %{conn: conn} do
    {:error, err} = call_time_to(conn, "3888385885")
    assert err =~ ~r/bad to param/i
  end

  defp call_time_to(conn, query_val) do
    conn
    |> Map.merge(%{params: %{"to" => query_val}})
    |> Castle.Plugs.Interval.TimeTo.parse()
  end
end
