defmodule Castle.Rollup.Query.MonthlyDownloads do
  import Ecto.Query

  def from_hourly(month) do
    month = Timex.beginning_of_month(month) |> Timex.to_date
    month_dtim = Timex.to_datetime(month)
    next_month = Timex.shift(month_dtim, months: 1)
    results = Castle.Repo.NewRelic.all from h in Castle.HourlyDownload,
      where: h.dtim >= ^month_dtim and h.dtim < ^next_month,
      select: %{podcast_id: h.podcast_id, episode_id: h.episode_id, count: sum(h.count)},
      group_by: [h.podcast_id, h.episode_id]
    Enum.map results, &(Map.put(&1, :month, month))
  end

  def podcast_total_until(podcast_id) do
    case logs_complete_until() do
      nil -> {0, default_until()}
      date ->
        count = Castle.Repo.NewRelic.one from d in Castle.MonthlyDownload, select: sum(d.count),
          where: d.podcast_id == ^podcast_id and d.month < ^date
        {count || 0, date}
    end
  end

  def episode_total_until(episode_id) do
    case logs_complete_until() do
      nil -> {0, default_until()}
      date ->
        count = Castle.Repo.NewRelic.one from d in Castle.MonthlyDownload, select: sum(d.count),
          where: d.episode_id == ^episode_id and d.month < ^date
        {count || 0, date}
    end
  end

  defp logs_complete_until do
    log = Castle.Repo.NewRelic.one from l in Castle.RollupLog,
      where: l.table_name == "monthly_downloads" and l.complete == true,
      order_by: [desc: :date], limit: 1
    if log do
      log.date |> Timex.shift(months: 1) |> Timex.to_date
    else
      nil
    end
  end

  defp default_until do
    Castle.RollupLog.beginning_of_time
  end
end
