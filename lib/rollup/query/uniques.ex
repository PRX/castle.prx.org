defmodule Castle.Rollup.Query.Uniques do
  import Ecto.Query

  def podcast(id, %{from: from, to: to, bucket: bucket}) do
    podcast(id, from, to, bucket.rollup)
  end
  def podcast(id, from, to, rollup) do
    query_podcasts(id, from, to, rollup) |> format_results()
  end

  defp query_podcasts(id, from, to, col_name) do
    {:ok, from_date} = from |> Timex.format("{YYYY}-{0M}-{0D}")
    {:ok, to_date} = to |> Timex.format("{YYYY}-{0M}-{0D}")

    col_name_atom = String.to_atom(col_name)
    Castle.Repo.all from h in Castle.WeeklyUnique,
      where: h.podcast_id == ^id and field(h, ^col_name_atom) >= ^from_date and field(h, ^col_name_atom) < ^to_date,
      select: %{:time => field(h, ^col_name_atom), :count => h.count},
      order_by: [asc: ^col_name_atom]
  end

  defp format_results([]), do: []
  defp format_results([%{count: n, time: t} | rest]) do
    IO.puts t
    [%{count: n, time: t}] ++ format_results(rest)
  end
end
