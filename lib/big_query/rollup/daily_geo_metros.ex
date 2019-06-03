defmodule BigQuery.Rollup.DailyGeoMetros do
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
      metro_code,
      count(*) as count
    FROM dt_downloads JOIN production.geonames ON (city_geoname_id = geoname_id)
    WHERE EXTRACT(DATE from timestamp) = @date_str AND is_duplicate = false
      AND feeder_podcast IS NOT NULL AND feeder_episode IS NOT NULL
      AND metro_code IS NOT NULL
    GROUP BY feeder_episode, metro_code
    """
  end

  defp format_results(rows, from) do
    day = Timex.beginning_of_day(from) |> Timex.to_date()
    Enum.map(rows, &(format_result(&1, day)))
  end

  defp format_result(row, day) do
    Map.put(row, :day, day)
  end
end
