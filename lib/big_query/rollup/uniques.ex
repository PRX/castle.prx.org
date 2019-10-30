defmodule BigQuery.Rollup.Uniques do
  defmacro __using__(_opts) do
    quote do
      defp sql do
        """
        SELECT
        feeder_podcast as podcast_id,
        count(distinct listener_id) as count
        FROM production.dt_downloads
        WHERE timestamp >= @start_at_str
        AND timestamp < @end_at_str
        AND is_duplicate = false
        AND feeder_podcast IS NOT NULL
        group by feeder_podcast
        order by feeder_podcast asc;
        """
      end
    end
  end
end
