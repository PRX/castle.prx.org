defmodule Castle.PlugsIntervalTimeFromTest do
  use Castle.ConnCase, async: true

  test "parses query timestamps", %{conn: conn} do
    {:ok, time_from} = call_time_from(conn, "2017-04-01T14:04:11Z")
    assert Timex.to_unix(time_from) == 1491055451
  end

  test "parses query dates", %{conn: conn} do
    {:ok, time_from} = call_time_from(conn, "2017-04-01")
    assert Timex.to_unix(time_from) == 1491004800
  end

  test "handles invalid params", %{conn: conn} do
    {:error, err} = call_time_from(conn, "3888385885")
    assert err =~ ~r/bad from param/i
  end

  test "requires the from param", %{conn: conn} do
    {:error, err} = call_time_from(conn, nil)
    assert err =~ ~r/missing required param/i
  end

  defp call_time_from(conn, query_val) do
    conn
    |> Map.merge(%{params: %{"from" => query_val}})
    |> Castle.Plugs.Interval.TimeFrom.parse()
  end
end
