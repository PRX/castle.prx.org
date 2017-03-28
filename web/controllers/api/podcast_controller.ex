defmodule Porter.API.PodcastController do
  use Porter.Web, :controller

  def index(conn, _params) do
    # conn |> fetch_query_params |> handle_query_params conn.params
    tbl = Env.get(:bq_dovetail_table)
    data = BigQuery.query """
      SELECT program, count(*) as count
      FROM #{tbl}
      WHERE impression_sent = true
      GROUP BY program
    """
    render conn, "index.json", programs: data, conn: conn
  end

  def show(conn, %{"id" => id}) do
    tbl = Env.get(:bq_dovetail_table)
    data = BigQuery.query """
      SELECT program, count(*) as count
      FROM #{tbl}
      WHERE program = '#{id}'
      AND impression_sent = true
      GROUP BY program
    """
    render conn, "show.json", program: hd(data), conn: conn
  end

  def downloads(conn, %{"id" => id}) do
    render conn, "downloads.json", conn: conn
  end
end
