defmodule Porter.PlugsIntervalTest do
  use Porter.ConnCase, async: true

  @default_from "2017-04-01T14:04:00Z"
  @default_to "2017-04-01T14:05:00Z"

  test "sets interval values in seconds", %{conn: conn} do
    assert get_interval(conn, "15m") == 900
    assert get_interval(conn, "1h") == 3600
    assert get_interval(conn, "1d") == 86400
  end

  test "validates interval values", %{conn: conn} do
    conn = call_interval(conn, "9a")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad interval param/i
  end

  test "guesses interval from the time window", %{conn: conn} do
    assert get_interval(conn, nil, "2017-04-01T00:01:00Z", "2017-04-01T00:02:00Z") == 900
    assert get_interval(conn, nil, "2017-04-01T00:01:00Z", "2017-04-01T12:00:00Z") == 3600
    assert get_interval(conn, nil, "2017-04-01T00:01:00Z", "2017-04-06T00:00:00Z") == 86400
  end

  test "rounds the lower time window down", %{conn: conn} do
    assert get_lower(conn, "15m", "2017-04-01T00:16:00Z") == "2017-04-01T00:15:00+00:00"
    assert get_lower(conn, "15m", "2017-04-01T00:59:59Z") == "2017-04-01T00:45:00+00:00"
    assert get_lower(conn, "1h", "2017-04-01T00:59:59Z") == "2017-04-01T00:00:00+00:00"
    assert get_lower(conn, "1h", "2017-04-01T23:22:44Z") == "2017-04-01T23:00:00+00:00"
    assert get_lower(conn, "1d", "2017-04-01T23:22:44Z") == "2017-04-01T00:00:00+00:00"
  end

  test "rounds the upper time window up", %{conn: conn} do
    assert get_upper(conn, "15m", "2017-04-01T23:45:00Z") == "2017-04-01T23:45:00+00:00"
    assert get_upper(conn, "15m", "2017-04-01T23:45:01Z") == "2017-04-02T00:00:00+00:00"
    assert get_upper(conn, "1h", "2017-04-01T00:59:59Z") == "2017-04-01T01:00:00+00:00"
    assert get_upper(conn, "1h", "2017-04-01T23:00:00Z") == "2017-04-01T23:00:00+00:00"
    assert get_upper(conn, "1d", "2017-04-01T12:12:12Z") == "2017-04-02T00:00:00+00:00"
  end

  test "validates the intervals per time window", %{conn: conn} do
    conn = call_interval(conn, "15m", "2017-04-01T00:00:00Z", "2017-04-04T00:00:00Z")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/time window too large/i
  end

  defp get_interval(conn, val, from \\ nil, to \\ nil) do
    conn |> get_assigns(val, from, to) |> Map.get(:interval)
  end

  defp get_lower(conn, val, from) do
    {:ok, lower} = conn |> get_assigns(val, from, @default_to) |> Map.get(:time_from) |> Timex.format("{ISO:Extended}")
    lower
  end

  defp get_upper(conn, val, to) do
    {:ok, upper} = conn |> get_assigns(val, @default_from, to) |> Map.get(:time_to) |> Timex.format("{ISO:Extended}")
    upper
  end

  defp get_assigns(conn, val, from, to) do
    conn |> call_interval(val, from, to) |> Map.get(:assigns)
  end

  defp call_interval(conn, val, from \\ nil, to \\ nil) do
    conn |> set_times(from, to) |> set_interval(val) |> Porter.Plugs.Interval.call(%{})
  end

  defp set_interval(conn, nil), do: conn
  defp set_interval(conn, interval) do
    conn |> Map.merge(%{params: %{"interval" => interval}})
  end

  defp set_times(conn, nil, nil), do: set_times(conn, @default_to, @default_from)
  defp set_times(conn, from_str, to_str) do
    {:ok, time_from} = Timex.parse(from_str, "{ISO:Extended}")
    {:ok, time_to} = Timex.parse(to_str, "{ISO:Extended}")
    conn
    |> Plug.Conn.assign(:time_from, time_from)
    |> Plug.Conn.assign(:time_to, time_to)
  end
end
