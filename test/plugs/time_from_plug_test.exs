defmodule Porter.PlugsTimeFromTest do
  use Porter.ConnCase, async: true

  test "parses query timestamps", %{conn: conn} do
    time_from = get_time(conn, "2017-04-01T14:04:11Z")
    assert Timex.to_unix(time_from) == 1491055451
  end

  test "parses query dates", %{conn: conn} do
    time_from = get_time(conn, "2017-04-01")
    assert Timex.to_unix(time_from) == 1491004800
  end

  test "handles invalid params", %{conn: conn} do
    conn = call_time_from(conn, "3888385885")
    assert conn.status == 400
    assert conn.resp_body =~ ~r/bad from param/i
  end

  test "requires the from param", %{conn: conn} do
    conn = call_time_from(conn, nil)
    assert conn.status == 400
    assert conn.resp_body =~ ~r/missing required param/i
  end

  defp get_time(conn, query_val) do
    conn |> call_time_from(query_val) |> Map.get(:assigns) |> Map.get(:time_from)
  end

  defp call_time_from(conn, query_val) do
    conn
    |> Map.merge(%{params: %{"from" => query_val}})
    |> Porter.Plugs.TimeFrom.call(%{})
  end
end
