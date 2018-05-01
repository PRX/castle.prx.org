defmodule BigQuery.Rollup do
  import BigQuery.Base.Query

  # a day isn't "complete" until this many seconds after it's over
  @buffer_seconds 900

  # get a single day of downloads bucketed by hours
  def hourly_downloads(), do: hourly_downloads(Timex.now)
  def hourly_downloads(dtim) do
    now = Timex.now()
    day = Timex.beginning_of_day(dtim)
    case completion_state(day, now) do
      :none ->
        {[], %{day: day, complete: false, hours_complete: 0}}
      :partial ->
        query_hourly_downloads(day) |> set_meta(:complete, false) |> set_meta(:hours_complete, hours_complete(now))
      :complete ->
        query_hourly_downloads(day) |> set_meta(:complete, true)
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

  defp query_hourly_downloads(day) do
    sql = """
      SELECT
        ANY_VALUE(feeder_podcast) as podcast_id,
        feeder_episode as episode_guid,
        EXTRACT(HOUR from timestamp) as hour,
        count(*) as count
      FROM production.downloads
      WHERE _PARTITIONTIME = @date_str AND is_duplicate = false
      GROUP BY feeder_episode, hour
      """
    {:ok, date_str} = Timex.format(day, "{YYYY}-{0M}-{0D}")
    {results, meta} = query(%{date_str: date_str}, sql)
    {
      Enum.map(results, &(format_result(&1, day))),
      Map.put(meta, :day, day)
    }
  end

  defp format_result(row, day) do
    Map.put(row, :hour, Timex.shift(day, hours: row.hour))
  end

  defp set_meta({results, meta}, key, value) do
    {results, Map.put(meta, key, value)}
  end
end
