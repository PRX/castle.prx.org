defmodule Castle.Plugs.Interval.Rollups do

  # we only rollup into these 2 intervals - any larger buckets
  # (week / month) can then be calculated from this data
  @hourly BigQuery.TimestampRollups.Hourly
  @daily BigQuery.TimestampRollups.Daily

  def parse(%{assigns: %{interval: %{bucket: bucket}}}) do
    case bucket.name() do
      "HOUR" -> {:ok, @hourly}
      "DAY" -> {:ok, @hourly}
      "WEEK" -> {:ok, @daily}
      "MONTH" -> {:ok, @daily}
    end
  end
end
