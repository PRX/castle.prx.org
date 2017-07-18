defmodule BigQuery.Impressions do
  import BigQuery.Base.Timestamp
  import BigQuery.Base.TimestampGroup

  def for_podcast(podcast_id, interval) do
    timestamp_query(
      Env.get(:bq_impressions_table),
      "feeder_podcast = @podcast_id",
      %{podcast_id: podcast_id},
      interval
    )
  end

  def for_podcast(podcast_id, interval, nil), do: for_podcast(podcast_id, interval)
  def for_podcast(podcast_id, interval, group) do
    group_query(
      Env.get(:bq_impressions_table),
      "feeder_podcast = @podcast_id",
      %{podcast_id: podcast_id},
      interval,
      group
    )
  end

  def for_episode(episode_guid, interval) do
    timestamp_query(
      Env.get(:bq_impressions_table),
      "feeder_episode = @episode_guid",
      %{episode_guid: episode_guid},
      interval
    )
  end

  def for_episode(episode_guid, interval, nil), do: for_episode(episode_guid, interval)
  def for_episode(episode_guid, interval, group) do
    group_query(
      Env.get(:bq_impressions_table),
      "feeder_episode = @episode_guid",
      %{episode_guid: episode_guid},
      interval,
      group
    )
  end
end
