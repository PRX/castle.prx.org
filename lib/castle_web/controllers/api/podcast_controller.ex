defmodule CastleWeb.API.PodcastController do
  use CastleWeb, :controller

  plug Castle.Plugs.ParseInt, "id" when action == :show

  def index(conn, _params) do
    render conn, "index.json", conn: conn, podcasts: Castle.Rollup.podcasts(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case assemble_data(id) do
      {nil, _} ->
        send_resp conn, 404, "Podcast #{id} not found"
      {total, trends} ->
        render conn, "show.json", conn: conn, podcast: id, total: total, trends: trends, meta: %{cached: true}
    end
  end

  defp assemble_data(id) do
    t1 = Task.async(fn -> Castle.Rollup.podcast_total(id) end)
    t2 = Task.async(fn -> Castle.Rollup.podcast_trends(id) end)
    {Task.await(t1), Task.await(t2)}
  end
end
