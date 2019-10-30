defmodule CastleWeb.API.ListenerController do
  use CastleWeb, :controller

  alias Castle.Rollup.Query.Uniques, as: Uniques

  @redis Application.get_env(:castle, :redis)

  def index(%{assigns: %{podcast: podcast, interval: intv}} = conn, _params) do
    data = Uniques.podcast(podcast.id, intv)
    render conn, "download.json", id: podcast.id, interval: intv, downloads: data
  end
end
