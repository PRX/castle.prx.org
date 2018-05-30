defmodule CastleWeb.API.DownloadController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Downloads, as: Downloads

  @redis Application.get_env(:castle, :redis)

  plug Castle.Plugs.AuthPodcast, "podcast_id"
  plug Castle.Plugs.AuthEpisode, "episode_guid"

  def index(%{assigns: %{podcast: podcast, interval: intv}} = conn, _params) do
    raw_data = case @redis.podcast_increments(podcast.id, intv) do
      {nil, _} -> Downloads.podcast(podcast.id, intv)
      {cached, nil} -> cached
      {cached, new_intv} -> Downloads.podcast(podcast.id, new_intv) ++ cached
    end
    data = bucketize(raw_data, intv)
    render conn, "download.json", id: podcast.id, interval: intv, downloads: data
  end

  def index(%{assigns: %{episode: episode, interval: intv}} = conn, _params) do
    raw_data = case @redis.episode_increments(episode.id, intv) do
      {nil, _} -> Downloads.episode(episode.id, intv)
      {cached, nil} -> cached
      {cached, new_intv} -> Downloads.episode(episode.id, new_intv) ++ cached
    end
    data = bucketize(raw_data, intv)
    render conn, "download.json", id: episode.id, interval: intv, downloads: data
  end
end
