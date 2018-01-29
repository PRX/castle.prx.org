defmodule BigQuery do

  alias BigQuery.Podcasts, as: Podcasts
  alias BigQuery.Episodes, as: Episodes
  alias BigQuery.Downloads, as: Downloads
  alias BigQuery.Impressions, as: Impressions

  defmodule Interval do
    @enforce_keys [:from, :to, :bucket, :rollup]
    defstruct [:from, :to, :bucket, :rollup]
  end

  defmodule Grouping do
    @enforce_keys [:name, :join, :groupby, :limit]
    defstruct [:name, :join, :groupby, limit: 10]
  end

  defdelegate podcasts(), to: Podcasts, as: :list
  defdelegate podcast(id), to: Podcasts, as: :show

  defdelegate episodes(), to: Episodes, as: :list
  defdelegate episode(guid), to: Episodes, as: :show

  defdelegate podcast_downloads(interval), to: Downloads, as: :for_podcasts
  defdelegate podcast_downloads(id, interval, group), to: Downloads, as: :group_podcast
  defdelegate podcast_impressions(interval), to: Impressions, as: :for_podcasts
  defdelegate podcast_impressions(id, interval, group), to: Impressions, as: :group_podcast

  defdelegate episode_downloads(interval), to: Downloads, as: :for_episodes
  defdelegate episode_downloads(guid, interval, group), to: Downloads, as: :group_episode
  defdelegate episode_impressions(interval), to: Impressions, as: :for_episodes
  defdelegate episode_impressions(guid, interval, group), to: Impressions, as: :group_episode
end
