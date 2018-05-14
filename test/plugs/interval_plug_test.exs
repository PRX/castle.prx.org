defmodule Castle.PlugsIntervalTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  @from "2017-04-01T14:04:00Z"
  @to "2017-04-02T14:05:00Z"

  test "parses hour intervals", %{conn: conn} do
    intv = get_interval(conn, @from, @to, "1h")
    assert_time intv.from, "2017-04-01T14:00:00Z"
    assert_time intv.to, "2017-04-02T15:00:00Z"
    assert intv.bucket.name == "HOUR"
  end

  test "parses day intervals", %{conn: conn} do
    intv = get_interval(conn, @from, @to, "1d")
    assert_time intv.from, "2017-04-01T14:00:00Z"
    assert_time intv.to, "2017-04-02T15:00:00Z"
    assert intv.bucket.name == "DAY"
  end

  test "parses week intervals", %{conn: conn} do
    intv = get_interval(conn, @from, @to, "1w")
    assert_time intv.from, "2017-04-01T14:00:00Z"
    assert_time intv.to, "2017-04-02T15:00:00Z"
    assert intv.bucket.name == "WEEK"
  end

  test "parses month intervals", %{conn: conn} do
    intv = get_interval(conn, @from, @to, "MONTH")
    assert_time intv.from, "2017-04-01T14:00:00Z"
    assert_time intv.to, "2017-04-02T15:00:00Z"
    assert intv.bucket.name == "MONTH"
  end

  test "handles time_from errors", %{conn: conn} do
    conn = call_interval(conn, nil, @to, "1h")
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
    conn = call_interval(conn, @from, "2020-01-01T00:00:00Z", "1h")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/time window too large/i
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
