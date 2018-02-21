defmodule Castle.Rollup.Jobs.Totals do
  import Castle.Redis.HashCache

  def podcasts_key(), do: "rollups.totals.podcasts"
  def episodes_key(), do: "rollups.totals.episodes"

  def run_podcasts() do
    hash_cache podcasts_key(), &Castle.Rollup.Jobs.Totals.query_podcasts/2
  end
  def run_episodes() do
    hash_cache episodes_key(), &Castle.Rollup.Jobs.Totals.query_episodes/2
  end

  def query_podcasts(from, to), do: query("feeder_podcast", from, to)
  def query_episodes(from, to), do: query("feeder_episode", from, to)

  defp query(_field, nil, nil), do: %{}
  defp query(field, nil, to) do
    sql = sql(field, "_PARTITIONTIME < @upper")
    {result, meta} = BigQuery.Base.Query.query %{upper: to}, sql
    {result_hash(result), meta}
  end
  defp query(field, from, to) do
    sql = sql(field, "_PARTITIONTIME >= @lower AND _PARTITIONTIME < @upper")
    {result, meta} = BigQuery.Base.Query.query %{lower: from, upper: to}, sql
    {result_hash(result), meta}
  end

  defp sql(field, where_sql) do
    """
      SELECT #{field} as key, COUNT(*) AS count
      FROM #{Env.get(:bq_downloads_table)}
      WHERE is_duplicate = false AND #{field} IS NOT NULL AND #{where_sql}
      GROUP BY #{field}
    """
  end

  defp result_hash(data), do: result_hash(data, %{})
  defp result_hash([%{count: n, key: key} | rest], acc), do: result_hash(rest, Map.put(acc, key, n))
  defp result_hash([], acc), do: acc
end
