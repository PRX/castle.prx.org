defmodule BigQuery.Base.Query do
  import BigQuery.Base.HTTP
  import BigQuery.Base.QueryParams
  import BigQuery.Base.QueryResult

  use Memoize

  def query(str), do: query(%{}, str)
  def query(params, sql), do: query(params, sql, nil)
  defmemo query(queryParams, sql, pageLimit), expires_in: 10 * 1000 do
    run_query(queryParams, sql, pageLimit)
  end

  def query_each(sql, func), do: query_each(%{}, sql, func)
  def query_each(params, sql, func), do: query_each(params, sql, func, nil)
  def query_each(params, sql, limit, func) do
    sql
    |> post_params(params, limit)
    |> post("queries")
    |> page_result(func)
    |> parse_meta()
  end

  defp run_query(queryParams, sql, pageLimit) do
    sql
    |> post_params(queryParams, pageLimit)
    |> post("queries")
    |> page_result()
    |> from_response()
  end

  defp post_params(sql, queryParams) do
    %{
      kind: "bigquery#queryRequest",
      query: sql,
      defaultDataset: %{
        datasetId: Env.get(:bq_dataset),
        projectId: Env.get(:bq_project_id)
      },
      useLegacySql: false,
      parameterMode: "NAMED",
      queryParameters: parameterize(queryParams),
    }
  end
  defp post_params(sql, queryParams, nil) do
    post_params(sql, queryParams)
  end
  defp post_params(sql, queryParams, pageLimit) do
    post_params(sql, queryParams) |> Map.put("maxResults", pageLimit)
  end

  defp page_result(%{"pageToken" => token, "jobReference" => %{"jobId" => job}} = data) do
    %{"pageToken" => token}
    |> get("queries/#{job}")
    |> merge_pages(data)
    |> page_result()
  end
  defp page_result(data) do
    data
  end
  defp page_result(%{"pageToken" => token, "jobReference" => %{"jobId" => job}} = data, func) do
    data |> parse_data() |> func.()
    %{"pageToken" => token}
    |> get("queries/#{job}")
    |> page_result(func)
  end
  defp page_result(data, func) do
    data |> parse_data() |> func.()
    data
  end

  defp merge_pages(%{"rows" => rows, "pageToken" => token}, %{"rows" => original_rows} = original_data) do
    original_data
    |> Map.put("rows", original_rows ++ rows)
    |> Map.put("pageToken", token)
  end
  defp merge_pages(%{"rows" => rows}, %{"rows" => original_rows} = original_data) do
    original_data
    |> Map.put("rows", original_rows ++ rows)
    |> Map.delete("pageToken")
  end
end
