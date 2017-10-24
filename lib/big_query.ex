defmodule BigQuery do

  alias BigQuery.Podcasts, as: Podcasts
  alias BigQuery.Episodes, as: Episodes
  alias BigQuery.Downloads, as: Downloads
  alias BigQuery.Impressions, as: Impressions

  defmodule Interval do
    @enforce_keys [:from, :to, :rollup]
    defstruct [:from, :to, :rollup]
  end

  defmodule Grouping do
    @enforce_keys [:name, :join, :groupby, :limit]
    defstruct [:name, :join, :groupby, limit: 10]
  end

  defdelegate podcasts(), to: Podcasts, as: :list
  defdelegate podcast(id), to: Podcasts, as: :show

  defdelegate episodes(), to: Episodes, as: :list
  defdelegate episode(guid), to: Episodes, as: :show

  defdelegate podcast_downloads(id, interval), to: Downloads, as: :for_podcast
  defdelegate podcast_downloads(id, interval, group), to: Downloads, as: :for_podcast
  defdelegate podcast_impressions(id, interval), to: Impressions, as: :for_podcast
  defdelegate podcast_impressions(id, interval, group), to: Impressions, as: :for_podcast

  defdelegate episode_downloads(guid, interval), to: Downloads, as: :for_episode
  defdelegate episode_downloads(guid, interval, group), to: Downloads, as: :for_episode
  defdelegate episode_impressions(id, interval), to: Impressions, as: :for_episode
  defdelegate episode_impressions(id, interval, group), to: Impressions, as: :for_episode
end
