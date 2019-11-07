defmodule BigQuery.Rollup.Last28Uniques do
  alias BigQuery.Base.Query, as: Query
  import BigQuery.Rollup.Uniques

  def query(func), do: query(Timex.now, func)
  def query(dtim, func) do
    BigQuery.Rollup.for_day dtim, fn(day) ->

      end_day = Timex.beginning_of_day(day)
      start_day = Timex.shift(end_day, days: -28)

      {start_at_str, end_at_str} = formatted_range(start_day, end_day)

      Query.query_each %{start_at_str: start_at_str, end_at_str: end_at_str}, sql(), fn(rows) ->
        format_results(rows, end_day) |> func.()
      end
    end
  end

  defp format_results(rows, end_day) do
    end_day = Timex.beginning_of_day(end_day) |> Timex.to_date()

    Enum.map(rows, &(format_result(&1, end_day)))
  end

  defp format_result(row, end_day) do
    row
    |> Map.put(:last_28, end_day)
  end
end
