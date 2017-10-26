defmodule BigQuery.Base.Timestamp do
  import BigQuery.Base.Query

  def timestamp_query(tbl, interval, group_by) do
    timestamp_params(interval) |> query(timestamp_sql(tbl, interval, group_by))
  end

  def timestamp_sql(tbl, interval, group_by) do
    """
    WITH intervals AS (#{timestamp_intervals(tbl, interval, group_by)})
    SELECT time, #{group_by}, count FROM intervals
    ORDER BY time ASC, #{group_by} ASC
    """ |> clean_sql()
  end

  def timestamp_intervals(tbl, interval, group_by) do
    """
    SELECT #{interval.rollup.rollup()} as time, #{group_by}, COUNT(*) as count
    FROM #{tbl}
    WHERE is_duplicate = false AND #{timestamp_partition()}
    GROUP BY time, #{group_by}
    """
  end

  def timestamp_partition do
    "timestamp >= @from_dtim AND timestamp < @to_dtim AND _PARTITIONTIME >= @pstart AND _PARTITIONTIME <= @pend"
  end

  def timestamp_params(interval) do
    %{
      from_dtim: interval.from,
      to_dtim: interval.to,
      pstart: Timex.beginning_of_day(interval.from),
      pend: Timex.end_of_day(interval.to),
    }
  end

  def clean_sql(str) do
    Regex.replace(~r/[ \n\r\t]+/, str, " ")
  end
end
