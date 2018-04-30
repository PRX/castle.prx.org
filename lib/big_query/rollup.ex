defmodule BigQuery.Rollup do
  import BigQuery.Base.Query

  # wait this many seconds for an hour's data to be in bigquery
  @buffer_seconds 300

  # get a single day of downloads bucketed by hours
  def daily_downloads(), do: daily_downloads(Timex.now)
  def daily_downloads(dtim), do: daily_downloads(dtim, Timex.now)
  def daily_downloads(dtim, now) do
    day = Timex.beginning_of_day(dtim)
    case max_hour(day, now) do
      :no_data -> :no_data
      :no_max ->
        params(day) |> query(sql()) |> format(day, :no_max)
      max ->
        params(day, max) |> query(sql(max)) |> format(day, max)
    end
  end

  def max_hour(day, now \\ Timex.now) do
    offset_now = Timex.shift(now, seconds: -@buffer_seconds)
    case Timex.compare(day, Timex.beginning_of_day(offset_now)) do
      -1 -> :no_max
      0 ->
        max_hour = floor_hour(offset_now)
        if max_hour.hour == 0, do: :no_data, else: max_hour
      1 -> :no_data
    end
  end

  defp floor_hour(dtim) do
    seconds = Timex.to_unix(dtim)
    Timex.from_unix(seconds - rem(seconds, 3600))
  end

  defp params(day, :no_max), do: params(day)
  defp params(day, max), do: params(day) |> Map.put(:max_hour, max)
  defp params(day) do
    {:ok, date_str} = Timex.format(day, "{YYYY}-{0M}-{0D}")
    %{date_str: date_str}
  end

  defp sql("" <> extra) do
    """
    SELECT
      ANY_VALUE(feeder_podcast) as podcast_id,
      feeder_episode as episode_guid,
      EXTRACT(HOUR from timestamp) as hour,
      count(*) as count
    FROM production.downloads
    WHERE _PARTITIONTIME = @date_str
      AND is_duplicate = false #{extra}
    GROUP BY feeder_episode, hour
    """
  end
  defp sql(_max), do: sql("AND timestamp < @max_hour")
  defp sql(), do: sql("")

  defp format({results, meta}, day, max) do
    {
      Enum.map(results, &(format_result(&1, day))),
      format_meta(meta, day, max)
    }
  end

  defp format_result(row, day) do
    Map.put(row, :hour, Timex.shift(day, hours: row.hour))
  end

  defp format_meta(meta, day), do: Map.put(meta, :day, day)
  defp format_meta(meta, day, :no_max), do: format_meta(meta, day) |> Map.put(:max_hour, 23)
  defp format_meta(meta, day, max), do: format_meta(meta, day) |> Map.put(:max_hour, max.hour - 1)
end
