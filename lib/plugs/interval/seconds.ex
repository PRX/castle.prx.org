defmodule Castle.Plugs.Interval.Seconds do

  @intervals %{
    "1d"  => 86400,
    "1h"  => 3600,
    "15m" => 900,
  }
  @max_in_window 1000

  def parse(%{params: %{"interval" => interval}} = conn) do
    if Map.has_key?(@intervals, interval) do
      validate_window(conn, @intervals[interval])
    else
      options = @intervals |> Map.keys() |> Enum.join(", ")
      {:error, "Bad interval param: use one of #{options}"}
    end
  end
  def parse(%{assigns: %{interval: %{from: from, to: to}}} = conn) do
    best_guess = case Timex.to_unix(to) - Timex.to_unix(from) do
      s when s > 345600 -> "1d" # > 4 days
      s when s > 28800 -> "1h"  # > 8 hours
      _ -> "15m"
    end
    validate_window(conn, @intervals[best_guess])
  end
  def parse(_conn) do
    {:error, "blah"}
  end

  defp validate_window(%{assigns: %{interval: %{from: from, to: to}}}, seconds) do
    window = Timex.to_unix(to) - Timex.to_unix(from)
    if (window / seconds) > @max_in_window do
      {:error, "Time window too large for specified interval"}
    else
      {:ok, seconds}
    end
  end
end
