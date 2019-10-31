defmodule Castle.Rollup.Query.Uniques do
  import Ecto.Query

  def podcast(id, %{from: from, to: to}, %{"interval" => interval_type}) do
    podcast(id, from, to, interval_type)
  end

  def podcast(id, from, to, interval_type) do
    {:ok, from_date} = from |> Timex.format("{YYYY}-{0M}-{0D}")
    {:ok, to_date} = to |> Timex.format("{YYYY}-{0M}-{0D}")
    query_podcasts(id, from_date, to_date, interval_type) |> format_results()
  end

  defp query_podcasts(id, from, to, "LAST_WEEK") do
    query_listeners_for_interval_type(id, from, to, :week, Castle.LastWeekUnique)
  end

  defp query_podcasts(id, from, to, "WEEK") do
    query_listeners_for_interval_type(id, from, to, :week, Castle.WeeklyUnique)
  end

  defp query_podcasts(id, from, to, "MONTH") do
    query_listeners_for_interval_type(id, from, to, :month, Castle.MonthlyUnique)
  end

  defp query_podcasts(id, from, to, "LAST_28") do
    query_listeners_for_interval_type(id, from, to, :last_28, Castle.Last28Unique)
  end

  defp query_listeners_for_interval_type(id, from, to, col_name, model) do
    Castle.Repo.all(
      from(h in model,
        where: h.podcast_id == ^id and field(h, ^col_name) >= ^from and field(h, ^col_name) < ^to,
        select: %{:time => field(h, ^col_name), :count => h.count},
        order_by: [asc: ^col_name]
      )
    )
  end

  defp format_results([]), do: []

  defp format_results([%{count: n, time: t} | rest]) do
    [%{count: n, time: t}] ++ format_results(rest)
  end
end
