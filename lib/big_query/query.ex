defmodule BigQuery.Query do
  import BigQuery.Base
  import BigQuery.QueryResult

  def query(str) do
    params = %{
      "kind": "bigquery#queryRequest",
      "query": str,
      "defaultDataset": %{
        "datasetId": Env.get(:bq_dataset),
        "projectId": Env.get(:bq_project_id)
      }
    }
    post("queries", params) |> from_response
  end

end
