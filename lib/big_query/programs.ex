defmodule BigQuery.Programs do
  import BigQuery.Base.Query

  def list(now \\ Timex.now) do
    """
    SELECT #{outer_selects()} FROM
    (#{select(:bq_downloads_table)}) a
    FULL JOIN
    (#{select(:bq_impressions_table)}) b
    ON (a.feeder_podcast = b.feeder_podcast)
    """
    |> query(params(now))
  end

  def show(podcast_id, now \\ Timex.now) do
    params = params(now) |> Map.put(:podcast, podcast_id)
    sql = """
      SELECT #{outer_selects()} FROM
      (#{select(:bq_downloads_table, podcast_id)}) a
      FULL JOIN
      (#{select(:bq_impressions_table, podcast_id)}) b
      ON (a.feeder_podcast = b.feeder_podcast)
    """
    query(sql, params) |> show_first()
  end

  defp show_first({[program | _rest], meta}), do: {program, meta}
  defp show_first({_, meta}), do: {%{}, meta}

  defp outer_selects do
    """
    IF(a.feeder_podcast IS NULL, b.feeder_podcast, a.feeder_podcast) AS feeder_podcast,
    a.past1 AS downloads_past1, a.past12 AS downloads_past12, a.past24 AS downloads_past24, a.past48 AS downloads_past48,
    b.past1 AS impressions_past1, b.past12 AS impressions_past12, b.past24 AS impressions_past24, b.past48 AS impressions_past48
    """
  end

  defp select(table, _podcast) do
    """
    SELECT feeder_podcast, #{counts()}
    FROM #{Env.get(table)}
    WHERE #{partitions()} AND is_duplicate = false AND feeder_podcast = @podcast
    GROUP BY feeder_podcast ORDER BY feeder_podcast ASC
    """
  end

  defp select(table) do
    """
    SELECT feeder_podcast, #{counts()}
    FROM #{Env.get(table)}
    WHERE #{partitions()} AND is_duplicate = false
    GROUP BY feeder_podcast ORDER BY feeder_podcast ASC
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
