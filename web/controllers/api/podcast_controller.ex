defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  def index(conn, _params) do
    render conn, "index.json", programs: BigQuery.programs(), conn: conn
  end

  def show(conn, %{"id" => id}) do
    render conn, "show.json", program: BigQuery.program(id), conn: conn
  end
end
