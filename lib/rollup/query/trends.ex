defmodule Castle.Rollup.Query.Trends do
  import Ecto.Query

  def podcast_trends(id, now \\ Timex.now) do
    today = Timex.beginning_of_day(now)
    start = Timex.shift(today, days: -13)

    results = Castle.Repo.all from h in Castle.HourlyDownload,
      where: h.podcast_id == ^id and h.dtim >= ^start and h.dtim <= ^now,
      select: %{day: fragment("dtim::date"), count: sum(h.count)},
      group_by: fragment("dtim::date")

    format_results(results, today)
  end

  def episode_trends(id, now \\ Timex.now) do
    today = Timex.beginning_of_day(now)
    start = Timex.shift(today, days: -13)

    results = Castle.Repo.all from h in Castle.HourlyDownload,
      where: h.episode_id == ^id and h.dtim >= ^start and h.dtim <= ^now,
      select: %{day: fragment("dtim::date"), count: sum(h.count)},
      group_by: fragment("dtim::date")

    format_results(results, today)
  end

  defp format_results(results, today) do
    %{
      today: find_counts(results, today, nil),
      yesterday: find_counts(results, Timex.shift(today, days: -1), today),
      this7days: find_counts(results, Timex.shift(today, days: -6), nil),
      previous7days: find_counts(results, nil, Timex.shift(today, days: -6)),
    }
  end

  defp find_counts([], _from, _to), do: 0
  defp find_counts([%{count: n, day: d} | rest], nil, to) do
    find_counts(rest, nil, to) + case Timex.compare(d, to) do
      -1 -> n
      _ -> 0
    end
  end
  defp find_counts([%{count: n, day: d} | rest], from, nil) do
    find_counts(rest, from, nil) + case Timex.compare(d, from) do
      -1 -> 0
      _ -> n
    end
  end
  defp find_counts([%{count: n, day: d} | rest], from, to) do
    find_counts(rest, from, to) + case {Timex.compare(d, from), Timex.compare(d, to)} do
      {-1, _} -> 0
      {_, -1} -> n
      {_, _} -> 0
    end
  end
end
