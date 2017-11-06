defmodule Castle.PlugsIntervalTest do
  use Castle.ConnCase, async: true

  @from "2017-04-01T14:04:00Z"
  @to "2017-04-01T14:05:00Z"
  @interval "15m"

  test "parses intervals", %{conn: conn} do
    intv = get_interval(conn, @from, @to, @interval)
    assert Timex.to_unix(intv.from) == 1491055200
    assert Timex.to_unix(intv.to) == 1491055200
    assert intv.rollup.name == "15MIN"
  end

  test "handles time_from errors", %{conn: conn} do
    conn = call_interval(conn, nil, @to, @interval)
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/missing required param: from/i
  end

  test "handles time_to errors", %{conn: conn} do
    conn = call_interval(conn, @from, "foo", "999")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad to param/i
  end

  test "handles seconds errors", %{conn: conn} do
    conn = call_interval(conn, @from, "2020-01-01T00:00:00Z", "15m")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/time window too large/i
  end

  test "rounds the lower time window down", %{conn: conn} do
    assert get_lower(conn, "15m", "2017-04-01T00:16:00Z") == "2017-04-01T00:15:00+00:00"
    assert get_lower(conn, "15m", "2017-04-01T00:59:59Z") == "2017-04-01T00:45:00+00:00"
    assert get_lower(conn, "1h", "2017-04-01T00:59:59Z") == "2017-04-01T00:00:00+00:00"
    assert get_lower(conn, "1h", "2017-04-01T23:22:44Z") == "2017-04-01T23:00:00+00:00"
    assert get_lower(conn, "1d", "2017-04-01T23:22:44Z") == "2017-04-01T00:00:00+00:00"
    assert get_lower(conn, "1w", "2017-04-01T23:22:44Z") == "2017-03-26T00:00:00+00:00"
    assert get_lower(conn, "1M", "2017-04-04T23:22:44Z") == "2017-04-01T00:00:00+00:00"
  end

  test "rounds the upper time window down", %{conn: conn} do
    assert get_upper(conn, "15m", "2017-04-01T23:45:00Z") == "2017-04-01T23:45:00+00:00"
    assert get_upper(conn, "15m", "2017-04-01T23:45:01Z") == "2017-04-01T23:45:00+00:00"
    assert get_upper(conn, "1h", "2017-04-01T00:59:59Z") == "2017-04-01T00:00:00+00:00"
    assert get_upper(conn, "1h", "2017-04-01T23:00:00Z") == "2017-04-01T23:00:00+00:00"
    assert get_upper(conn, "1d", "2017-04-01T12:12:12Z") == "2017-04-01T00:00:00+00:00"
    assert get_upper(conn, "1w", "2017-04-02T12:12:12Z") == "2017-04-02T00:00:00+00:00"
    assert get_upper(conn, "1M", "2017-04-02T12:12:12Z") == "2017-04-01T00:00:00+00:00"
  end

  defp get_lower(conn, interval, from) do
    {:ok, lower} = conn |> get_interval(from, @to, interval) |> Map.get(:from) |> Timex.format("{ISO:Extended}")
    lower
  end

  defp get_upper(conn, interval, to) do
    {:ok, upper} = conn |> get_interval(@from, to, interval) |> Map.get(:to) |> Timex.format("{ISO:Extended}")
    upper
  end

  defp get_interval(conn, from, to, interval) do
    conn |> call_interval(from, to, interval) |> Map.get(:assigns) |> Map.get(:interval)
  end

  defp call_interval(conn, from, to, interval) do
    conn
    |> set_param("from", from)
    |> set_param("to", to)
    |> set_param("interval", interval)
    |> Castle.Plugs.Interval.call(%{})
  end

  defp set_param(conn, _key, nil), do: conn
  defp set_param(%{params: params} = conn, key, val) do
    Map.put(conn, :params, Map.put(params, key, val))
  end
end
