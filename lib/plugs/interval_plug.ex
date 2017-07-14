defmodule Castle.Plugs.Interval do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> assign(:interval, %{})
    |> interval_part(:from, &Castle.Plugs.Interval.TimeFrom.parse/1)
    |> interval_part(:to, &Castle.Plugs.Interval.TimeTo.parse/1)
    |> interval_part(:seconds, &Castle.Plugs.Interval.Seconds.parse/1)
    |> round_time_window()
    |> interval_struct()
  end

  defp interval_part(%{status: nil, assigns: %{interval: intv}} = conn, key, valfn) do
    case valfn.(conn) do
      {:ok, val} ->
        conn |> assign(:interval, Map.put(intv, key, val))
      {:error, err} ->
        conn |> send_resp(400, err) |> halt()
    end
  end
  defp interval_part(conn, _key, _valfn), do: conn

  defp round_time_window(%{status: nil, assigns: %{interval: intv}} = conn) do
    lower = Timex.to_unix(intv.from)
    upper = Timex.to_unix(intv.to)
    lower_down = Timex.from_unix(lower - rem(lower, intv.seconds))
    upper_up = Timex.from_unix(round(Float.ceil(upper / intv.seconds) * intv.seconds))
    assign(conn, :interval, %{from: lower_down, to: upper_up, seconds: intv.seconds})
  end
  defp round_time_window(conn), do: conn

  defp interval_struct(%{status: nil, assigns: %{interval: intv}} = conn) do
    conn |> assign(:interval, struct!(BigQuery.Interval, intv))
  end
  defp interval_struct(conn), do: conn
end
