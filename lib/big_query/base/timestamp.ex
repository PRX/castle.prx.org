defmodule BigQuery.Base.Timestamp do
  import BigQuery.Base.Query

  def timestamp_query(tbl, interval, group_by) do
    timestamp_params(interval)
    |> query(timestamp_sql(tbl, interval, group_by))
    |> group(interval)
  end

  def timestamp_sql(tbl, interval, group_by) do
    """
    WITH intervals AS (#{timestamp_intervals(tbl, interval, group_by)})
    SELECT time, ARRAY_AGG(STRUCT(#{group_by}, count)) as counts FROM intervals
    GROUP BY time ORDER BY time ASC
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

  def group({data, meta}, intv) do
    data = intv.rollup.range(intv.from, intv.to, false)
           |> insert_counts(data)
    {data, meta}
  end

  defp insert_counts([t1 | times], [%{time: t2, counts: counts} | rest] = all) do
    if Timex.to_unix(t1) == Timex.to_unix(t2) do
      count_map = counts |> Enum.map(&List.to_tuple/1) |> Map.new()
      [{t1, count_map}] ++ insert_counts(times, rest)
    else
      [{t1, %{}}] ++ insert_counts(times, all)
    end
  end
  defp insert_counts([], _), do: []
  defp insert_counts([t1 | times], []), do: [{t1, %{}}] ++ insert_counts(times, [])
end
