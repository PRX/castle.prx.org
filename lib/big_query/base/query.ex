defmodule BigQuery.Base.Query do
  import BigQuery.Base.HTTP
  import BigQuery.Base.QueryParams
  import BigQuery.Base.QueryResult

  def query(str), do: query(str, %{})

  def query(str, queryParams) do
    params = %{
      "kind": "bigquery#queryRequest",
      "query": str,
      "defaultDataset": %{
        "datasetId": Env.get(:bq_dataset),
        "projectId": Env.get(:bq_project_id)
      },
      "useLegacySql": false,
      "parameterMode": "NAMED",
      "queryParameters": parameterize(queryParams)
    }
    post("queries", params) |> from_response
  end

end
