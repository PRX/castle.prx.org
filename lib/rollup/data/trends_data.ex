defmodule Castle.Rollup.Data.Trends do
  alias Castle.Redis.Interval.Getter, as: Getter

  # TODO: this is a bit inside-baseball
  @podcast_downloads_key "downloads.podcasts.DAY"
  @episode_downloads_key "downloads.episodes.DAY"
  @daily BigQuery.TimestampRollups.Daily

  def podcast(id) do
    {last7, this7, yesterday, today, tomorrow} = get_dates()
    hits = get_from_interval(@podcast_downloads_key, id, last7, tomorrow)
    %{
      last7: sum_for_range(last7, this7, hits),
      this7: sum_for_range(this7, tomorrow, hits),
      yesterday: sum_for_range(yesterday, today, hits),
      today: sum_for_range(today, tomorrow, hits),
    }
  end

  def episode(guid) do
    {last7, this7, yesterday, today, tomorrow} = get_dates()
    hits = get_from_interval(@episode_downloads_key, guid, last7, tomorrow)
    %{
      last7: sum_for_range(last7, this7, hits),
      this7: sum_for_range(this7, tomorrow, hits),
      yesterday: sum_for_range(yesterday, today, hits),
      today: sum_for_range(today, tomorrow, hits),
    }
  end

  defp get_from_interval(key_prefix, ident, from, to) do
    Getter.get_hits(key_prefix, ident, from, to, @daily)
  end

  defp sum_for_range(_from, _to, []), do: 0
  defp sum_for_range(from, to, [%{count: count, time: time} | hits]) do
    if Timex.to_unix(time) >= Timex.to_unix(from) && Timex.to_unix(time) < Timex.to_unix(to) do
      count + sum_for_range(from, to, hits)
    else
      sum_for_range(from, to, hits)
    end
  end

  defp get_dates() do
    today = Timex.now |> Timex.beginning_of_day
    tomorrow = Timex.shift(today, days: 1)
    yesterday = Timex.shift(today, days: -1)
    this7 = Timex.shift(today, days: -6)
    last7 = Timex.shift(today, days: -13)
    {last7, this7, yesterday, today, tomorrow}
  end
end
