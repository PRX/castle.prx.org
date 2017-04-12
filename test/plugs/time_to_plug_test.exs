defmodule Castle.PlugsTimeToTest do
  use Castle.ConnCase, async: true

  test "sets a default slightly in the future", %{conn: conn} do
    time_to = get_time(conn)
    now = Timex.now
    later = Timex.shift(now, seconds: 100)

    assert time_to
    assert Timex.compare(time_to, now) > 0
    assert Timex.compare(time_to, later) < 0
  end

  test "parses query timestamps", %{conn: conn} do
    time_to = get_time(conn, "2017-04-01T14:04:11Z")
    assert Timex.to_unix(time_to) == 1491055451
  end

  test "parses query dates", %{conn: conn} do
    time_to = get_time(conn, "2017-04-01")
    assert Timex.to_unix(time_to) == 1491004800
  end

  test "handles invalid params", %{conn: conn} do
    conn = call_time_to(conn, "3888385885")
    assert conn.status == 400
    assert conn.halted == true
    assert conn.resp_body =~ ~r/bad to param/i
  end

  defp get_time(conn, query_val \\ nil) do
    conn |> call_time_to(query_val) |> Map.get(:assigns) |> Map.get(:time_to)
  end

  defp call_time_to(conn, query_val) do
    conn
    |> Map.merge(%{params: %{"to" => query_val}})
    |> Castle.Plugs.TimeTo.call(%{})
  end
end
