defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  def index(conn, _params) do
    {programs, meta} = BigQuery.programs()
    render conn, "index.json", conn: conn, programs: programs, meta: meta
  end

  def show(conn, %{"id" => id}) do
    {program, meta} = BigQuery.program(id)
    render conn, "show.json", conn: conn, program: program, meta: meta
  end
end
