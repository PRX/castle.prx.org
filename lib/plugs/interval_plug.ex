defmodule Porter.Plugs.Interval do
  import Plug.Conn

  @intervals %{
    "1d"  => 86400,
    "1h"  => 3600,
    "15m" => 900,
  }
  @max_in_window 100

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> set_interval()
    |> round_time_window()
    |> validate_window()
  end

  defp set_interval(%{status: nil, params: %{"interval" => interval}} = conn) do
    if Map.has_key?(@intervals, interval) do
      assign conn, :interval, @intervals[interval]
    else
      options = @intervals |> Map.keys() |> Enum.join(", ")
      send_resp conn, 400, "Bad interval param: use one of #{options}"
    end
  end
  defp set_interval(%{status: nil} = conn) do
    {time_from, time_to} = interval_params(conn)
    best_guess = case Timex.to_unix(time_to) - Timex.to_unix(time_from) do
      s when s > 345600 -> "1d" # > 4 days
      s when s > 28800 -> "1h"  # > 8 hours
      _ -> "15m"
    end
    assign conn, :interval, @intervals[best_guess]
  end

  defp round_time_window(%{status: nil} = conn) do
    {time_from, time_to, interval} = interval_params(conn)
    lower = Timex.to_unix(time_from)
    upper = Timex.to_unix(time_to)
    lower_down = Timex.from_unix(lower - rem(lower, interval))
    upper_up = Timex.from_unix(round(Float.ceil(upper / interval) * interval))
    conn
    |> assign(:time_from, lower_down)
    |> assign(:time_to, upper_up)
  end
  defp round_time_window(conn), do: conn

  defp validate_window(%{status: nil} = conn) do
    {time_from, time_to, interval} = interval_params(conn)
    window = Timex.to_unix(time_to) - Timex.to_unix(time_from)
    if (window / interval) > @max_in_window do
      send_resp conn, 400, "Time window too large for specified interval"
    else
      conn
    end
  end
  defp validate_window(conn), do: conn

  defp interval_params(%{assigns: %{time_from: time_from, time_to: time_to, interval: interval}}),
    do: {time_from, time_to, interval}
  defp interval_params(%{assigns: %{time_from: time_from, time_to: time_to}}),
    do: {time_from, time_to}
end
