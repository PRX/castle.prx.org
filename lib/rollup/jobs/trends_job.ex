defmodule Castle.Rollup.Jobs.Trends do
  # TODO: import "public" redis api from the application
  import Castle.Redis.PartitionCache

  # old - all days before today
  # new - just data for today
  def run() do
    partition "rollup.trends", &Castle.Rollup.Jobs.Trends.combine/1, [
      {ttl_eod(Timex.now()), &Castle.Rollup.Jobs.Trends.old_part/0},
      {300, &Castle.Rollup.Jobs.Trends.new_part/1}]
  end

  def ttl_eod(now) do
    end_of_day = Timex.end_of_day(now) |> Timex.shift(microseconds: 1)
    Timex.diff(end_of_day, now, :seconds)
  end

  def get() do
    partition_get "rollup.trends", 2, &Castle.Rollup.Jobs.Trends.combine/1
  end

  def combine(parts), do: parts

  def old_part() do
    sql = sql("_PARTITIONTIME >= @lower AND _PARTITIONTIME < @upper")
    end_dtim = Timex.beginning_of_day(Timex.now())
    start_dtim = Timex.shift(end_dtim, days: -13)
    params = params(%{lower: start_dtim, upper: end_dtim})
    {result, meta} = BigQuery.Base.Query.query(params, sql)
    {end_dtim, result, Map.put(meta, :job, [{nil, end_dtim}])}
  end

  def new_part(start_dtim) do
    sql = sql("_PARTITIONTIME >= @lower")
    params = params(%{lower: start_dtim})
    {result, meta} = BigQuery.Base.Query.query(params, sql)
    {nil, result, Map.put(meta, :job, [{start_dtim, nil}])}
  end

  defp sql(where_sql) do
    """
      SELECT feeder_podcast, feeder_episode,
        COUNTIF(timestamp >= @last7 AND timestamp < @this7) as last7,
        COUNTIF(timestamp >= @this7) as this7,
        COUNTIF(timestamp >= @yesterday AND timestamp < @today) as yesterday,
        COUNTIF(timestamp >= @today) as today
      FROM #{Env.get(:bq_downloads_table)}
      WHERE is_duplicate = false AND feeder_podcast IS NOT NULL
      AND feeder_episode IS NOT NULL AND #{where_sql}
      GROUP BY feeder_podcast, feeder_episode
    """
  end

  defp params(params) do
    today = Timex.beginning_of_day(Timex.now())
    %{
      last7: Timex.shift(today, days: -13),
      this7: Timex.shift(today, days: -6),
      yesterday: Timex.shift(today, days: -1),
      today: today,
    } |> Map.merge(params)
  end
end
