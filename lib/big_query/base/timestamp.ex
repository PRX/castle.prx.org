defmodule BigQuery.Base.Timestamp do
  import BigQuery.Base.Query

  def timestamp_query(tbl, where_sql, params, from_dtim, to_dtim, interval_s) do
    timestamp_sql(tbl, where_sql)
    |> query(timestamp_params(from_dtim, to_dtim, interval_s) |> Map.merge(params))
  end

  def timestamp_sql(tbl, where_sql) do
    """
    SELECT
      TIMESTAMP_SECONDS(UNIX_SECONDS(timestamp) - MOD(UNIX_SECONDS(timestamp), @interval_s)) as time,
      count(*) as count
    FROM #{tbl}
    WHERE is_duplicate = false
      AND timestamp >= @from_dtim
      AND timestamp < @to_dtim
      AND _PARTITIONTIME >= @pstart
      AND _PARTITIONTIME <= @pend
      AND #{where_sql}
    GROUP BY 1
    ORDER BY 1 ASC
    """
  end

  def timestamp_params(from_dtim, to_dtim, interval_s) do
    %{
      interval_s: interval_s,
      from_dtim: from_dtim,
      to_dtim: to_dtim,
      pstart: Timex.beginning_of_day(from_dtim),
      pend: Timex.end_of_day(to_dtim)
    }
  end
end
