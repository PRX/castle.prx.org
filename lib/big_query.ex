defmodule BigQuery do

  defdelegate programs(), to: BigQuery.Programs, as: :list
  defdelegate program(id), to: BigQuery.Programs, as: :show

  defdelegate podcast_downloads(id, from, to, interval),
    to: BigQuery.Downloads,
    as: :for_podcast
  defdelegate episode_downloads(guid, from, to, interval),
    to: BigQuery.Downloads,
    as: :for_episode

  defdelegate podcast_impressions(id, from, to, interval),
    to: BigQuery.Impressions,
    as: :for_podcast
  defdelegate episode_impressions(guid, from, to, interval),
    to: BigQuery.Impressions,
    as: :for_episode
end
