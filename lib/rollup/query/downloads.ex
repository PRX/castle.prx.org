defmodule Castle.Rollup.Query.Downloads do
  import Ecto.Query

  def podcast(id, %{from: from, to: to, bucket: bucket}) do
    podcast(id, from, to, bucket.rollup)
  end
  def podcast(id, from, to, trunc) do
    query_podcasts(id, from, to, trunc) |> format_results()
  end

  def episode(id, %{from: from, to: to, bucket: bucket}) do
    episode(id, from, to, bucket.rollup)
  end
  def episode(id, from, to, trunc) do
    query_episodes(id, from, to, trunc) |> format_results()
  end

  defp query_podcasts(id, from, to, "week") do
    Castle.Repo.NewRelic.all from h in Castle.HourlyDownload,
      where: h.podcast_id == ^id and h.dtim >= ^from and h.dtim < ^to,
      select: %{time: fragment("date_trunc('week',dtim+interval '1 day')-interval '1 day' as time"), count: sum(h.count)},
      group_by: fragment("time"),
      order_by: [asc: fragment("time")]
  end
  defp query_podcasts(id, from, to, trunc) do
    Castle.Repo.NewRelic.all from h in Castle.HourlyDownload,
      where: h.podcast_id == ^id and h.dtim >= ^from and h.dtim < ^to,
      select: %{time: fragment("date_trunc(?,dtim) as time", ^trunc), count: sum(h.count)},
      group_by: fragment("time"),
      order_by: [asc: fragment("time")]
  end

  defp query_episodes(id, from, to, "week") do
    Castle.Repo.NewRelic.all from h in Castle.HourlyDownload,
      where: h.episode_id == ^id and h.dtim >= ^from and h.dtim < ^to,
      select: %{time: fragment("date_trunc('week',dtim+interval '1 day')-interval '1 day' as time"), count: sum(h.count)},
      group_by: fragment("time"),
      order_by: [asc: fragment("time")]
  end
  defp query_episodes(id, from, to, trunc) do
    Castle.Repo.NewRelic.all from h in Castle.HourlyDownload,
      where: h.episode_id == ^id and h.dtim >= ^from and h.dtim < ^to,
      select: %{time: fragment("date_trunc(?,dtim) as time", ^trunc), count: sum(h.count)},
      group_by: fragment("time"),
      order_by: [asc: fragment("time")]
  end

  defp format_results([]), do: []
  defp format_results([%{count: n, time: t} | rest]) do
    [%{count: n, time: Timex.to_datetime(t)}] ++ format_results(rest)
  end
end
