defmodule Castle.Plugs.Interval.Rollups do

  @timestamp_rollups [
    BigQuery.TimestampRollups.Daily,
    BigQuery.TimestampRollups.Hourly,
    BigQuery.TimestampRollups.Monthly,
    BigQuery.TimestampRollups.QuarterHourly,
    BigQuery.TimestampRollups.Weekly,
  ]
  @max_in_window 1000

  def parse(%{params: %{"interval" => interval}} = conn) do
    match = Enum.find(@timestamp_rollups, &(&1.is_a?(interval)))
    if match do
      validate_window(conn, match)
    else
      options = @timestamp_rollups |> Enum.map(&(&1.name)) |> Enum.join(", ")
      {:error, "Bad interval param: use one of #{options}"}
    end
  end
  def parse(%{assigns: %{interval: %{from: from, to: to}}} = conn) do
    best_guess = case Timex.to_unix(to) - Timex.to_unix(from) do
      s when s > 31104000 -> BigQuery.TimestampRollups.Monthly # > 360 days
      s when s > 6048000 -> BigQuery.TimestampRollups.Weekly # > 70 days
      s when s > 345600 -> BigQuery.TimestampRollups.Daily # > 4 days
      s when s > 28800 -> BigQuery.TimestampRollups.Hourly  # > 8 hours
      _ -> BigQuery.TimestampRollups.QuarterHourly
    end
    validate_window(conn, best_guess)
  end
  def parse(_conn) do
    {:error, "Invalid interval params"}
  end

  defp validate_window(%{assigns: %{interval: %{from: from, to: to}}}, rollup) do
    if rollup.count_range(from, to) > @max_in_window do
      {:error, "Time window too large for specified interval"}
    else
      {:ok, rollup}
    end
  end
end
