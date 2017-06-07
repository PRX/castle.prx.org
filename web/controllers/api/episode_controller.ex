defmodule Castle.API.EpisodeController do
  use Castle.Web, :controller

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    val = fn() -> @bigquery.episodes() end
    {episodes, meta} = @redis.cached "episode.index", val, ttl: @index_ttl, conn: conn
    render conn, "index.json", conn: conn, episodes: episodes, meta: meta
  end

  def show(conn, %{"id" => id}) do
    val = fn() -> @bigquery.episode(id) end
    {episode, meta} = @redis.cached "episode.show.#{id}", val, ttl: @show_ttl, conn: conn
    render conn, "show.json", conn: conn, episode: episode, meta: meta
  end
end
