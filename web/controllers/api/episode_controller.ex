defmodule Castle.API.EpisodeController do
  use Castle.Web, :controller

  @redis Application.get_env(:castle, :redis)
  @bigquery Application.get_env(:castle, :bigquery)

  @index_ttl 900
  @show_ttl 300

  def index(conn, _params) do
    {episodes, meta} = @redis.cached "episode.index", @index_ttl, fn() -> @bigquery.episodes() end
    render conn, "index.json", conn: conn, episodes: episodes, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {episode, meta} = @redis.cached "episode.show.#{id}", @show_ttl, fn() -> @bigquery.episode(id) end
    render conn, "show.json", conn: conn, episode: episode, meta: meta
  end
end
