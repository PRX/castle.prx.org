defmodule Castle.API.PodcastController do
  use Castle.Web, :controller

  alias Castle.Rollup.Data.Totals, as: Totals

  plug Castle.Plugs.ParseInt, "id" when action == :show

  def index(conn, _params) do
    render conn, "index.json", conn: conn, podcasts: Totals.podcasts(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case Totals.podcast(id) do
      nil -> send_resp conn, 404, "Podcast #{id} not found"
      pod -> render conn, "show.json", conn: conn, podcast: pod, meta: %{cached: true}
    end
  end
end
