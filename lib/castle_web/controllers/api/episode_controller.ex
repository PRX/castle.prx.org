defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller

  def index(conn, _params) do
    render conn, "index.json", conn: conn, episodes: Castle.Rollup.episodes(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case assemble_data(id) do
      {nil, _} ->
        send_resp conn, 404, "Episode #{id} not found"
      {total, trends} ->
        render conn, "show.json", conn: conn, episode: id, total: total, trends: trends, meta: %{cached: true}
    end
  end

  defp assemble_data(id) do
    t1 = Task.async(fn -> Castle.Rollup.episode_total(id) end)
    t2 = Task.async(fn -> Castle.Rollup.episode_trends(id) end)
    {Task.await(t1), Task.await(t2)}
  end
end
