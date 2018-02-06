defmodule CastleWeb.API.EpisodeController do
  use CastleWeb, :controller

  alias Castle.Rollup.Data.Totals, as: Totals
  alias Castle.Rollup.Data.Trends, as: Trends

  def index(conn, _params) do
    render conn, "index.json", conn: conn, episodes: Totals.episodes(), meta: %{cached: true}
  end

  def show(conn, %{"id" => id}) do
    case assemble_data(id) do
      {nil, _} ->
        send_resp conn, 404, "Episode #{id} not found"
      {ep, trends} ->
        render conn, "show.json", conn: conn, episode: ep, trends: trends, meta: %{cached: true}
    end
  end

  defp assemble_data(id) do
    t1 = Task.async(fn -> Totals.episode(id) end)
    t2 = Task.async(fn -> Trends.episode(id) end)
    {Task.await(t1), Task.await(t2)}
  end
end
