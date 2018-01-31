defmodule Castle.Plugs.Interval.Rollups do

  # we only rollup into these 2 intervals - any larger buckets
  # (week / month) can then be calculated from this data
  @hourly BigQuery.TimestampRollups.Hourly
  @daily BigQuery.TimestampRollups.Daily

  def parse(%{assigns: %{interval: %{from: from, to: to, bucket: bucket}}}) do
    case bucket.name() do
      "HOUR" -> {:ok, @hourly}
      "DAY" ->
        start_of_hour = Timex.to_unix(@hourly.floor(from))
        start_of_day = Timex.to_unix(@daily.floor(from))
        end_of_hour = Timex.to_unix(@hourly.ceiling(to))
        end_of_day = Timex.to_unix(@daily.ceiling(to))

        # we can rollup by day instead of hour, if starting/ending at 00:00:00
        if start_of_hour == start_of_day && end_of_hour == end_of_day do
          {:ok, @daily}
        else
          {:ok, @hourly}
        end
      "WEEK" -> {:ok, @daily}
      "MONTH" -> {:ok, @daily}
    end
  end
end
