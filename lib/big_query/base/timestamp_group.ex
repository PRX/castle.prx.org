defmodule BigQuery.Base.TimestampGroup do
  import BigQuery.Base.Query
  import BigQuery.Base.Timestamp,
    only: [timestamp_intervals: 4, timestamp_params: 2]

  def group_query(tbl, where_sql, params, interval, grouping) do
    params
    |> timestamp_params(interval)
    |> group_params(grouping)
    |> query(group_sql(tbl, where_sql, grouping))
  end

  def group_sql(tbl, where_sql, grouping) do
    intervals = timestamp_intervals(tbl, where_sql, grouping.groupby, "JOIN #{grouping.join}")
    """
    WITH
      intervals AS (#{intervals}),
      top_groups AS (#{top_groups("intervals", grouping.groupby)})
    SELECT
      time,
      SUM(count) as count,
      IF(rank IS NULL, NULL, ANY_VALUE(#{grouping.groupby})) AS display,
      rank
    FROM intervals
    LEFT JOIN top_groups USING (#{grouping.groupby})
    GROUP BY time, rank
    ORDER BY time asc, rank asc
    """
  end

  def group_params(params, grouping) do
    params
    |> Map.put(:grouplimit, grouping.limit)
  end

  def top_groups(tbl, key) do
    """
    SELECT
      value as #{key},
      ROW_NUMBER() OVER(ORDER BY sum DESC) AS rank
    FROM (
      SELECT APPROX_TOP_SUM(#{key}, count, @grouplimit) as tops
      FROM #{tbl}
      WHERE #{key} IS NOT NULL
    ) as top_groups, UNNEST(tops)
    """
  end
end
