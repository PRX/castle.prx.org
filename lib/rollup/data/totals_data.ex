defmodule Castle.Rollup.Data.Totals do
  import Castle.Rollup.Jobs.Totals
  import Castle.Redis.HashCache
  alias Castle.Redis.Interval.Getter, as: Getter

  # TODO: this is a bit inside-baseball
  @podcast_downloads_key "downloads.podcasts.DAY"
  @episode_downloads_key "downloads.episodes.DAY"
  @daily BigQuery.TimestampRollups.Daily

  def podcast(id) do
    hash_fetch podcasts_key(), id, fn(from) ->
      get_from_interval(@podcast_downloads_key, id, from)
    end
  end

  def podcasts(), do: hash_fetch(podcasts_key())

  def episode(guid) do
    hash_fetch episodes_key(), guid, fn(from) ->
      get_from_interval(@episode_downloads_key, guid, from)
    end
  end

  def episodes(), do: hash_fetch(episodes_key())

  defp get_from_interval(key_prefix, ident, from) do
    tomorrow = Timex.now |> Timex.end_of_day |> Timex.shift(microseconds: 1)
    Getter.get_hits(key_prefix, ident, from, tomorrow, @daily)
    |> sum_interval_hits()
  end

  defp sum_interval_hits([]), do: 0
  defp sum_interval_hits([%{count: n} | rest]), do: n + sum_interval_hits(rest)
end
