defmodule Castle.Plugs.Interval do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> assign(:interval, %{})
    |> interval_part(:from, &Castle.Plugs.Interval.TimeFrom.parse/1)
    |> interval_part(:to, &Castle.Plugs.Interval.TimeTo.parse/1)
    |> interval_part(:rollup, &Castle.Plugs.Interval.Seconds.parse/1)
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
    assign(conn, :interval, %{
      from: round_down(intv.from, intv.rollup),
      to: round_up(intv.to, intv.rollup),
      rollup: intv.rollup,
    })
  end
  defp round_time_window(conn), do: conn

  defp round_down(time, "MONTH"), do: Timex.beginning_of_month(time)
  defp round_down(time, "WEEK"), do: Timex.beginning_of_week(time, 7)
  defp round_down(time, "DAY"), do: Timex.beginning_of_day(time)
  defp round_down(time, seconds) do
    Timex.from_unix(Timex.to_unix(time) - rem(Timex.to_unix(time), seconds))
  end

  defp round_up(time, "MONTH"), do: Timex.shift(Timex.end_of_month(time), microseconds: 1)
  defp round_up(time, "WEEK"), do: Timex.shift(Timex.end_of_week(time, 7), microseconds: 1)
  defp round_up(time, "DAY"), do: Timex.shift(Timex.end_of_day(time), microseconds: 1)
  defp round_up(time, seconds) do
    Timex.from_unix(round(Float.ceil(Timex.to_unix(time) / seconds) * seconds))
  end

  defp interval_struct(%{status: nil, assigns: %{interval: intv}} = conn) do
    conn |> assign(:interval, struct!(BigQuery.Interval, intv))
  end
  defp interval_struct(conn), do: conn
end
