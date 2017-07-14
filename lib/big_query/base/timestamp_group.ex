defmodule BigQuery.Base.TimestampGroup do
  import BigQuery.Base.Query
  import BigQuery.Base.Timestamp,
    only: [timestamp_seconds: 0, timestamp_partition: 0, timestamp_params: 2]

  def group_query(tbl, where_sql, params, interval, grouping) do
    params
    |> timestamp_params(interval)
    |> group_params(grouping)
    |> query(group_sql(tbl, where_sql, grouping))
  end

  def group_sql(tbl, where_sql, grouping) do
    IO.puts """
    SELECT time,
      IF (row < @grouplimit, #{grouping.display}, 'Other') AS display,
      SUM(count) AS count
    FROM (
      SELECT
        #{timestamp_seconds()} AS time,
        #{grouping.fkey},
        count(*) AS count,
        ROW_NUMBER() OVER(ORDER BY count(*) desc) AS row
      FROM #{tbl}
      WHERE is_duplicate = false AND #{timestamp_partition()} AND #{where_sql}
      GROUP BY time, #{grouping.fkey}
    ) JOIN #{grouping.table} ON (#{grouping.fkey} = #{grouping.key})
    """
  end

  def group_params(params, grouping) do
    params
    |> Map.put(:grouplimit, grouping.limit)
  end
end
