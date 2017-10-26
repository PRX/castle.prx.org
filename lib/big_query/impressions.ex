defmodule BigQuery.Impressions do
  import BigQuery.Base.Timestamp
  import BigQuery.Base.TimestampGroup

  def for_podcasts(interval) do
    timestamp_query(Env.get(:bq_impressions_table), interval, "feeder_podcast")
  end

  def for_episodes(interval) do
    timestamp_query(Env.get(:bq_impressions_table), interval, "feeder_episode")
  end

  def group_podcast(podcast_id, interval, group) do
    group_query(
      Env.get(:bq_impressions_table),
      "feeder_podcast = @podcast_id",
      %{podcast_id: podcast_id},
      interval,
      group
    )
  end

  def group_episode(episode_guid, interval, group) do
    group_query(
      Env.get(:bq_impressions_table),
      "feeder_episode = @episode_guid",
      %{episode_guid: episode_guid},
      interval,
      group
    )
  end
end
