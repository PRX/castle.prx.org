defmodule BigQuery do

  defmodule Interval do
    @enforce_keys [:from, :to, :seconds]
    defstruct [:from, :to, :seconds]
  end

  defmodule Grouping do
    @enforce_keys [:name, :table, :key, :display, :fkey, :limit]
    defstruct [:name, :table, :key, :display, :fkey, limit: 10]
  end

  defdelegate podcasts(), to: BigQuery.Podcasts, as: :list
  defdelegate podcast(id), to: BigQuery.Podcasts, as: :show

  defdelegate episodes(), to: BigQuery.Episodes, as: :list
  defdelegate episode(guid), to: BigQuery.Episodes, as: :show

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
