defmodule Castle.API.EpisodeController do
  use Castle.Web, :controller

  alias Castle.Rollup.Data.Totals, as: Totals

  def index(conn, _params) do
    render conn, "index.json", conn: conn, episodes: Totals.episodes(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case Totals.episode(id) do
      nil -> send_resp conn, 404, "Episode #{id} not found"
      ep -> render conn, "show.json", conn: conn, episode: ep, meta: %{cached: true}
    end
  end
end
