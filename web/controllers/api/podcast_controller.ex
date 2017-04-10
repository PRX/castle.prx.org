defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  def index(conn, _params) do
    {podcasts, meta} = BigQuery.podcasts()
    render conn, "index.json", conn: conn, podcasts: podcasts, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {podcast, meta} = BigQuery.podcast(id)
    render conn, "show.json", conn: conn, podcast: podcast, meta: meta
  end
end
