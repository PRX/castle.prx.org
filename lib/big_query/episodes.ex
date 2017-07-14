defmodule BigQuery.Episodes do
  import BigQuery.Base.Query

  def list(now \\ Timex.now, limit \\ 20) do
    sql = """
    SELECT #{outer_selects()} FROM
    (#{select(:bq_downloads_table)}) a
    FULL JOIN
    (#{select(:bq_impressions_table)}) b
    ON (a.feeder_episode = b.feeder_episode)
    LIMIT #{limit}
    """
    query params(now), sql
  end

  def show(episode_guid, now \\ Timex.now) do
    params = params(now) |> Map.put(:episode, episode_guid)
    sql = """
      SELECT #{outer_selects()} FROM
      (#{select(:bq_downloads_table, episode_guid)}) a
      FULL JOIN
      (#{select(:bq_impressions_table, episode_guid)}) b
      ON (a.feeder_episode = b.feeder_episode)
    """
    query(params, sql) |> show_first()
  end

  defp show_first({[episode | _rest], meta}), do: {episode, meta}
  defp show_first({_, meta}), do: {%{}, meta}

  defp outer_selects do
    """
    IF(a.feeder_episode IS NULL, b.feeder_episode, a.feeder_episode) AS feeder_episode,
    a.past1 AS downloads_past1, a.past12 AS downloads_past12, a.past24 AS downloads_past24, a.past48 AS downloads_past48,
    b.past1 AS impressions_past1, b.past12 AS impressions_past12, b.past24 AS impressions_past24, b.past48 AS impressions_past48
    """
  end

  defp select(table, _episode) do
    """
    SELECT feeder_episode, #{counts()}
    FROM #{Env.get(table)}
    WHERE #{partitions()} AND is_duplicate = false AND feeder_episode = @episode
    GROUP BY feeder_episode ORDER BY feeder_episode ASC
    """
  end

  defp select(table) do
    """
    SELECT feeder_episode, #{counts()}
    FROM #{Env.get(table)}
    WHERE #{partitions()} AND is_duplicate = false
    GROUP BY feeder_episode ORDER BY feeder_episode ASC
    """
  end

  defp counts do
    """
    COUNTIF(timestamp > @past1) AS past1,
    COUNTIF(timestamp > @past12) AS past12,
    COUNTIF(timestamp > @past24) AS past24,
    COUNTIF(timestamp > @past48) AS past48
    """
  end

  defp partitions do
    "_PARTITIONTIME >= @pstart AND _PARTITIONTIME <= @pend"
  end

  defp params(now) do
    %{
      past1:  Timex.shift(now, hours: -1),
      past12: Timex.shift(now, hours: -12),
      past24: Timex.shift(now, hours: -24),
      past48: Timex.shift(now, hours: -48),
      pstart: Timex.beginning_of_day(Timex.shift(now, hours: -48)),
      pend:   Timex.end_of_day(now),
    }
  end
end
