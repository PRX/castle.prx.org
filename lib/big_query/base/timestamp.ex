defmodule BigQuery.Base.Timestamp do
  import BigQuery.Base.Query

  def timestamp_query(tbl, where_sql, params, interval) do
    params
    |> timestamp_params(interval)
    |> query(timestamp_sql(tbl, interval, where_sql))
  end

  def timestamp_sql(tbl, interval, where_sql) do
    """
    WITH intervals AS (#{timestamp_intervals(tbl, interval, where_sql)})
    SELECT time, count FROM intervals
    ORDER BY time ASC
    """
  end

  def timestamp_intervals(tbl, interval, where_sql), do: timestamp_intervals(tbl, interval, where_sql, nil)
  def timestamp_intervals(tbl, interval, where_sql, extra_fld, joiner \\ "") do
    """
    SELECT
      #{timestamp_rollup(interval)} as time,
      #{comma_after(extra_fld)}
      COUNT(*) as count
    FROM #{tbl} #{joiner}
    WHERE
      is_duplicate = false
      AND #{timestamp_partition()}
      AND #{where_sql}
    GROUP BY time#{comma_before(extra_fld)}
    """
  end

  def timestamp_rollup(%{rollup: "MONTH"}), do: "TIMESTAMP_TRUNC(timestamp, MONTH)"
  def timestamp_rollup(%{rollup: "WEEK"}), do: "TIMESTAMP_TRUNC(timestamp, WEEK)"
  def timestamp_rollup(%{rollup: "DAY"}), do: "TIMESTAMP_TRUNC(timestamp, DAY)"
  def timestamp_rollup(%{rollup: _seconds}) do
    "TIMESTAMP_SECONDS(UNIX_SECONDS(timestamp) - MOD(UNIX_SECONDS(timestamp), @interval_s))"
  end

  def timestamp_partition do
    "timestamp >= @from_dtim AND timestamp < @to_dtim AND _PARTITIONTIME >= @pstart AND _PARTITIONTIME <= @pend"
  end

  def timestamp_params(params, interval) do
    params
    |> Map.put(:interval_s, interval.rollup)
    |> Map.put(:from_dtim, interval.from)
    |> Map.put(:to_dtim, interval.to)
    |> Map.put(:pstart, Timex.beginning_of_day(interval.from))
    |> Map.put(:pend, Timex.end_of_day(interval.to))
  end

  defp comma_after(nil), do: ""
  defp comma_after(fld), do: "#{fld},"

  defp comma_before(nil), do: ""
  defp comma_before(fld), do: ", #{fld}"
end
