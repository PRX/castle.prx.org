defmodule Castle.Rollup.Query.MonthlyDownloads do
  import Ecto.Query

  def all(month) do
    month = Timex.beginning_of_month(month) |> Timex.to_date
    month_dtim = Timex.to_datetime(month)
    next_month = Timex.shift(month_dtim, months: 1)
    results = Castle.Repo.all from h in Castle.HourlyDownload,
      where: h.dtim >= ^month_dtim and h.dtim < ^next_month,
      select: %{podcast_id: h.podcast_id, episode_id: h.episode_id, count: sum(h.count)},
      group_by: [h.podcast_id, h.episode_id]
    Enum.map results, &(Map.put(&1, :month, month))
  end
end
