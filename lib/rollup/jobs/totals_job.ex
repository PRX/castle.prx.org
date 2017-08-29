defmodule Castle.Rollup.Jobs.Totals do
  # TODO: import "public" redis api from the application
  import Castle.Redis.PartitionCache

  # old - all non-today partitions from the beginning of time - 15 day cache
  # mid - intermediate query to pick up the slack - 1 day cache
  # new - always the current-date-partition - 5 minute cache
  def run() do
    partition "rollup.totals", &Castle.Rollup.Jobs.Totals.combine/1, [
      {1296000, &Castle.Rollup.Jobs.Totals.old_part/0},
      {86400, &Castle.Rollup.Jobs.Totals.mid_part/1},
      {300, &Castle.Rollup.Jobs.Totals.new_part/1}]
  end

  def get() do
    partition_get "rollup.totals", 3, &Castle.Rollup.Jobs.Totals.combine/1
  end

  def combine(parts) do
    parts
    |> Enum.sort(&(&1.feeder_episode >= &2.feeder_episode))
    |> Enum.reduce([], &combine_parts/2)
  end

  def old_part() do
    end_dtim = Timex.beginning_of_day(Timex.now())
    sql = sql("_PARTITIONTIME < @upper")
    {result, meta} = BigQuery.Base.Query.query %{upper: end_dtim}, sql
    {end_dtim, result, Map.put(meta, :job, [{nil, end_dtim}])}
  end

  def mid_part(start_dtim) do
    end_dtim = Timex.beginning_of_day(Timex.now())
    if start_dtim == end_dtim do
      {end_dtim, [], %{cached: true}}
    else
      sql = sql("_PARTITIONTIME >= @lower AND _PARTITIONTIME < @upper")
      {result, meta} = BigQuery.Base.Query.query %{lower: start_dtim, upper: end_dtim}, sql
      {end_dtim, result, Map.put(meta, :job, [{start_dtim, end_dtim}])}
    end
  end

  def new_part(start_dtim) do
    sql = sql("_PARTITIONTIME >= @lower")
    {result, meta} = BigQuery.Base.Query.query %{lower: start_dtim}, sql
    {nil, result, Map.put(meta, :job, [{start_dtim, nil}])}
  end

  defp sql(where_sql) do
    """
      SELECT feeder_podcast, feeder_episode, COUNT(*) AS count
      FROM #{Env.get(:bq_downloads_table)}
      WHERE is_duplicate = false AND feeder_podcast IS NOT NULL
      AND feeder_episode IS NOT NULL AND #{where_sql}
      GROUP BY feeder_podcast, feeder_episode
    """
  end

  defp combine_parts(%{count: n, feeder_episode: guid} = part, [last | rest]) do
    if last.feeder_episode == guid do
      [Map.put(last, :count, last.count + n)] ++ rest
    else
      [part] ++ [last] ++ rest
    end
  end
  defp combine_parts(part, _), do: [part]
end
