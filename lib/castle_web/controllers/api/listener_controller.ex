defmodule CastleWeb.API.ListenerController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Uniques, as: Uniques

  def index(%{assigns: %{podcast: podcast, interval: intv}} = conn, params) do
    data = Uniques.podcast(podcast.id, intv, params)
    render(conn, "download.json", id: podcast.id, interval: intv, downloads: data)
  end
end
