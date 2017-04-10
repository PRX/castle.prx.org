defmodule Porter.API.EpisodeController do
  use Porter.Web, :controller

  def index(conn, _params) do
    {episodes, meta} = BigQuery.episodes()
    render conn, "index.json", conn: conn, episodes: episodes, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {episode, meta} = BigQuery.episode(id)
    render conn, "show.json", conn: conn, episode: episode, meta: meta
  end
end
