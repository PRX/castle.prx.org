defmodule CastleWeb.API.TotalController do
  use CastleWeb, :controller

  def index(%{assigns: %{podcast: podcast, interval: intv, group: group}} = conn, _params) do
    data = group.totals.podcast(podcast.id, intv, group)
    render conn, "total.json", id: podcast.id, interval: intv, group: group, downloads: data
  end

  def index(%{assigns: %{episode: episode, interval: intv, group: group}} = conn, _params) do
    data = group.totals.episode(episode.id, intv, group)
    render conn, "total.json", id: episode.id, interval: intv, group: group, downloads: data
  end
end
