defmodule BigQuery.Impressions do
  import BigQuery.Base.Timestamp

  def for_podcast(podcast_id, from_dtim, to_dtim, interval_s) do
    timestamp_query(
      Env.get(:bq_impressions_table),
      "feeder_podcast = @podcast_id",
      %{podcast_id: podcast_id},
      from_dtim,
      to_dtim,
      interval_s
    )
  end

  def for_episode(episode_guid, from_dtim, to_dtim, interval_s) do
    timestamp_query(
      Env.get(:bq_impressions_table),
      "feeder_episode = @episode_guid",
      %{episode_guid: episode_guid},
      from_dtim,
      to_dtim,
      interval_s
    )
  end
end
