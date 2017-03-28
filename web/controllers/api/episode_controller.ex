defmodule Porter.API.EpisodeController do
  use Porter.Web, :controller

  def index(conn, _params) do
    # render conn, "index.json"
    text conn, "Episode index"
  end

  def show(conn, %{"id" => id}) do
    text conn, "Episode id #{id}"
  end
end
