defmodule Porter.DemoController do
  use Porter.Web, :controller

  def index(conn, _params) do
    tbl = Env.get(:bq_dovetail_table)
    data = BigQuery.query """
      SELECT program, count(*) as count
      FROM #{tbl}
      GROUP BY program
    """
    render conn, "index.json", programs: data
  end
end
