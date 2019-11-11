defmodule BigQuery.Rollup.WeeklyUniques do
  alias BigQuery.Base.Query, as: Query
  import BigQuery.Rollup.Uniques

  def query(func), do: query(Timex.now, func)
  def query(dtim, func) do
    BigQuery.Rollup.for_day dtim, fn(day) ->

      start_day = Timex.beginning_of_week(day, 7)
      end_day = Timex.shift(start_day, weeks: 1)
      {start_at_str, end_at_str} = formatted_range(start_day, end_day)

      Query.query_each %{start_at_str: start_at_str, end_at_str: end_at_str}, sql(), fn(rows) ->
        format_results(rows, start_day) |> func.()
      end
    end
  end

  defp format_results(rows, start_day) do
    start_day = Timex.beginning_of_day(start_day) |> Timex.to_date()

    Enum.map(rows, &(format_result(&1, start_day)))
  end

  defp format_result(row, start_day) do
    row
    |> Map.put(:week, start_day)
  end
end
