defmodule BigQuery.Rollup.Uniques do
  def sql do
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

  def formatted_range(start_day, end_day) do
    {:ok, start_at_str} = Timex.format(start_day, "{YYYY}-{0M}-{0D}")
    {:ok, end_at_str} = Timex.format(end_day, "{YYYY}-{0M}-{0D}")

    {start_at_str, end_at_str}
  end
end
