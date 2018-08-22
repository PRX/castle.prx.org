defmodule Castle.Rollup.Query.Totals do
  import Ecto.Query

  alias Castle.Rollup.Query.MonthlyDownloads, as: MonthlyDownload

  def podcast_totals(id, now \\ Timex.now) do
    {count, until_date} = MonthlyDownload.podcast_total_until(id)
    hour_count = Castle.Repo.NewRelic.one from h in Castle.HourlyDownload, select: sum(h.count),
      where: h.podcast_id == ^id and h.dtim >= ^Timex.to_datetime(until_date) and h.dtim < ^now
    count + (hour_count || 0)
  end

  def episode_totals(id, now \\ Timex.now) do
    {count, until_date} = MonthlyDownload.episode_total_until(id)
    hour_count = Castle.Repo.NewRelic.one from h in Castle.HourlyDownload, select: sum(h.count),
      where: h.episode_id == ^id and h.dtim >= ^Timex.to_datetime(until_date) and h.dtim < ^now
    count + (hour_count || 0)
  end

  def add_cached(total, cached_counts) do
    cached_total = Enum.reduce(cached_counts, 0, fn(%{count: n}, acc) -> acc + n end)
    total + cached_total
  end
end
