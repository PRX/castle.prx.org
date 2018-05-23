defmodule BigQuery.Rollup do

  # a day isn't "complete" until this many seconds after it's over
  @buffer_seconds 900

  defdelegate hourly_downloads(), to: BigQuery.Rollup.HourlyDownloads, as: :query
  defdelegate hourly_downloads(d), to: BigQuery.Rollup.HourlyDownloads, as: :query

  def for_day(dtim, query_fn) do
    now = Timex.now()
    day = Timex.beginning_of_day(dtim)
    case completion_state(day, now) do
      :none ->
        {[], %{day: day, complete: false, hours_complete: 0}}
      :partial ->
        query_fn.(day) |> set_meta(:day, day) |> set_meta(:complete, false) |> set_meta(:hours_complete, hours_complete(now))
      :complete ->
        query_fn.(day) |> set_meta(:day, day) |> set_meta(:complete, true)
    end
  end

  def completion_state(day, now) do
    today = Timex.beginning_of_day(now)
    buffer_today = Timex.shift(now, seconds: -@buffer_seconds) |> Timex.beginning_of_day()
    case {Timex.compare(day, today), Timex.compare(day, buffer_today)} do
      {1, _} -> :none # future
      {0, _} -> :partial # today
      {-1, -1} -> :complete # > 15min since that day
      {-1, _} -> :partial # day is < 15min over
    end
  end

  def hours_complete(now), do: Timex.shift(now, seconds: -@buffer_seconds).hour

  defp set_meta({results, meta}, key, value) do
    {results, Map.put(meta, key, value)}
  end
end
