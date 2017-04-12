defmodule Porter.API.EpisodeController do
  use Porter.Web, :controller

  alias Porter.Redis.CachedResponse, as: Redis

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    {episodes, meta} = Redis.cached "episode.index", @index_ttl, fn() -> BigQuery.episodes() end
    render conn, "index.json", conn: conn, episodes: episodes, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {episode, meta} = Redis.cached "episode.show.#{id}", @show_ttl, fn() -> BigQuery.episode(id) end
    render conn, "show.json", conn: conn, episode: episode, meta: meta
  end
end
