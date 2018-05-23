defmodule Castle.Rollup.Query.Trends do
  import Ecto.Query

  def podcast_trends(id, now \\ Timex.now) do
    start = Timex.beginning_of_day(now) |> Timex.shift(days: -13)

    get_trends = fn ->
      Castle.Repo.all from h in Castle.HourlyDownload,
        where: h.podcast_id == ^id and h.dtim >= ^start and h.dtim < ^now,
        select: %{time: fragment("dtim::date"), count: sum(h.count)},
        group_by: fragment("dtim::date")
    end
    get_total = fn ->
      Castle.Repo.one from h in Castle.HourlyDownload,
        where: h.podcast_id == ^id and h.dtim < ^now,
        select: sum(h.count)
    end

    t1 = Task.async(get_trends)
    t2 = Task.async(get_total)
    format_results Task.await(t1), Task.await(t2), now
  end

  def episode_trends(id, now \\ Timex.now) do
    start = Timex.beginning_of_day(now) |> Timex.shift(days: -13)

    get_trends = fn ->
      Castle.Repo.all from h in Castle.HourlyDownload,
        where: h.episode_id == ^id and h.dtim >= ^start and h.dtim < ^now,
        select: %{time: fragment("dtim::date"), count: sum(h.count)},
        group_by: fragment("dtim::date")
    end
    get_total = fn ->
      Castle.Repo.one from h in Castle.HourlyDownload,
        where: h.episode_id == ^id and h.dtim < ^now,
        select: sum(h.count)
    end

    t1 = Task.async(get_trends)
    t2 = Task.async(get_total)
    format_results Task.await(t1), Task.await(t2), now
  end

  def add_cached(trends, cached, now \\ Timex.now) do
    cached_total = Enum.reduce(cached, 0, fn(%{count: n}, acc) -> acc + n end)
    cached_trends = format_results(cached, cached_total, now)
    %{
      total: trends.total + cached_trends.total,
      today: trends.today + cached_trends.today,
      yesterday: trends.yesterday + cached_trends.yesterday,
      this7days: trends.this7days + cached_trends.this7days,
      previous7days: trends.previous7days + cached_trends.previous7days,
    }
  end

  defp format_results(trends, total, now) do
    today = Timex.beginning_of_day(now)
    tomorrow = Timex.shift(today, days: 1)
    %{
      total: total || 0,
      today: find_counts(trends, today, tomorrow),
      yesterday: find_counts(trends, Timex.shift(today, days: -1), today),
      this7days: find_counts(trends, Timex.shift(today, days: -6), tomorrow),
      previous7days: find_counts(trends, Timex.shift(today, days: -13), Timex.shift(today, days: -6)),
    }
  end

  defp find_counts([], _from, _to), do: 0
  defp find_counts([%{count: n, time: t} | rest], from, to) do
    find_counts(rest, from, to) + case {Timex.compare(t, from), Timex.compare(t, to)} do
      {-1, _} -> 0
      {_, -1} -> n
      {_, _} -> 0
    end
  end
end
