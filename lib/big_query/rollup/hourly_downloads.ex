defmodule BigQuery.Rollup.HourlyDownloads do
  alias BigQuery.Base.Query, as: Query

  def query(func), do: query(Timex.now, func)
  def query(dtim, func) do
    BigQuery.Rollup.for_day dtim, fn(day) ->
      {:ok, date_str} = Timex.format(day, "{YYYY}-{0M}-{0D}")
      Query.query_each %{date_str: date_str}, sql(), fn(rows) ->
        format_results(rows, day) |> func.()
      end
    end
  end

  defp sql do
    """
    SELECT
      ANY_VALUE(feeder_podcast) as podcast_id,
      feeder_episode as episode_id,
      EXTRACT(HOUR from timestamp) as hour,
      count(*) as count
    FROM dt_downloads
    WHERE EXTRACT(DATE from timestamp) = @date_str AND is_duplicate = false
      AND feeder_podcast IS NOT NULL AND feeder_episode IS NOT NULL
    GROUP BY feeder_episode, hour
    """
  end

  defp format_results(rows, day) do
    Enum.map(rows, &(format_result(&1, day)))
  end

  defp format_result(%{hour: hour} = row, day) do
    row
    |> Map.put(:dtim, Timex.shift(day, hours: hour))
    |> Map.delete(:hour)
  end
end
