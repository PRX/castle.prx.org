defmodule BigQuery.Rollup.DailyGeoCountries do
  alias BigQuery.Base.Query, as: Query

  def query(), do: query(Timex.now)
  def query(dtim) do
    BigQuery.Rollup.for_day dtim, fn(day) ->
      {:ok, date_str} = Timex.format(day, "{YYYY}-{0M}-{0D}")
      Query.query(%{date_str: date_str}, sql()) |> format_results(day)
    end
  end

  defp sql do
    """
    SELECT
      ANY_VALUE(feeder_podcast) as podcast_id,
      feeder_episode as episode_id,
      country_iso_code,
      count(*) as count
    FROM dt_downloads JOIN production.geonames ON (country_geoname_id = geoname_id)
    WHERE EXTRACT(DATE from timestamp) = @date_str AND is_duplicate = false
      AND feeder_podcast IS NOT NULL AND feeder_episode IS NOT NULL
      AND country_iso_code IS NOT NULL
    GROUP BY feeder_episode, country_iso_code
    """
  end

  defp format_results({rows, meta}, from) do
    day = Timex.beginning_of_day(from) |> Timex.to_date()
    {Enum.map(rows, &(format_result(&1, day))), meta}
  end

  defp format_result(row, day) do
    Map.put(row, :day, day)
  end
end
