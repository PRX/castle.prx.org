defmodule CastleWeb.API.PodcastController do
  use CastleWeb, :controller

  alias Castle.Rollup.Data.Totals, as: Totals
  alias Castle.Rollup.Data.Trends, as: Trends

  plug Castle.Plugs.ParseInt, "id" when action == :show

  def index(conn, _params) do
    render conn, "index.json", conn: conn, podcasts: Totals.podcasts(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case assemble_data(id) do
      {nil, _} ->
        send_resp conn, 404, "Podcast #{id} not found"
      {pod, trends} ->
        render conn, "show.json", conn: conn, podcast: pod, trends: trends, meta: %{cached: true}
    end
  end

  defp assemble_data(id) do
    t1 = Task.async(fn -> Totals.podcast(id) end)
    t2 = Task.async(fn -> Trends.podcast(id) end)
    {Task.await(t1), Task.await(t2)}
  end
end
