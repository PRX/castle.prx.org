defmodule BigQuery.Rollup do
  # a day isn't "complete" until this many seconds after it's over
  @buffer_seconds 900

  defdelegate hourly_downloads(func), to: BigQuery.Rollup.HourlyDownloads, as: :query
  defdelegate hourly_downloads(d, func), to: BigQuery.Rollup.HourlyDownloads, as: :query
  defdelegate daily_agents(func), to: BigQuery.Rollup.DailyAgents, as: :query
  defdelegate daily_agents(d, func), to: BigQuery.Rollup.DailyAgents, as: :query
  defdelegate daily_geo_countries(func), to: BigQuery.Rollup.DailyGeoCountries, as: :query
  defdelegate daily_geo_countries(d, func), to: BigQuery.Rollup.DailyGeoCountries, as: :query
  defdelegate daily_geo_metros(func), to: BigQuery.Rollup.DailyGeoMetros, as: :query
  defdelegate daily_geo_metros(d, func), to: BigQuery.Rollup.DailyGeoMetros, as: :query
  defdelegate daily_geo_subdivs(func), to: BigQuery.Rollup.DailyGeoSubdivs, as: :query
  defdelegate daily_geo_subdivs(d, func), to: BigQuery.Rollup.DailyGeoSubdivs, as: :query
  defdelegate monthly_uniques(d, func), to: BigQuery.Rollup.MonthlyUniques, as: :query
  defdelegate weekly_uniques(d, func), to: BigQuery.Rollup.WeeklyUniques, as: :query
  defdelegate last_week_uniques(d, func), to: BigQuery.Rollup.LastWeekUniques, as: :query
  defdelegate last_28_uniques(d, func), to: BigQuery.Rollup.Last28Uniques, as: :query

  def for_day(dtim, query_fn) do
    now = Timex.now()
    day = Timex.beginning_of_day(dtim)

    case current_day_completion_state(day, now) do
      :none ->
        %{day: day, complete: false, hours_complete: 0}

      :partial ->
        query_fn.(day)
        |> Map.put(:day, day)
        |> Map.put(:complete, false)
        |> Map.put(:hours_complete, hours_complete(now))

      :complete ->
        query_fn.(day) |> Map.put(:day, day) |> Map.put(:complete, true)
    end
  end

  def current_day_completion_state(day, now) do
    today = Timex.beginning_of_day(now)
    buffer_today = Timex.shift(now, seconds: -@buffer_seconds) |> Timex.beginning_of_day()

    case {Timex.compare(day, today), Timex.compare(day, buffer_today)} do
      # future
      {1, _} -> :none
      # today
      {0, _} -> :partial
      # > 15min since that day
      {-1, -1} -> :complete
      # day is < 15min over
      {-1, _} -> :partial
    end
  end

  def hours_complete(now), do: Timex.shift(now, seconds: -@buffer_seconds).hour
end
