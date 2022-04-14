defmodule BigQuery.Base.Load do
  require Logger
  import BigQuery.Base.HTTP

  @max_job_wait_seconds 30

  def reload(table, csv_data) do
    try do
      upload("jobs", post_params(table), csv_data) |> wait_for_job()
    rescue
      e in RuntimeError ->
        case e do
          %{message: m} -> {:error, m}
          _ -> {:error, inspect(e)}
        end
    end
  end

  defp post_params(table_name) do
    %{
      configuration: %{
        load: %{
          destinationTable: %{
            projectId: Env.get(:bq_project_id),
            datasetId: Env.get(:bq_dataset),
            tableId: table_name
          },
          createDisposition: "CREATE_NEVER",
          writeDisposition: "WRITE_TRUNCATE",
          sourceFormat: "NEWLINE_DELIMITED_JSON"
        }
      }
    }
  end

  defp wait_for_job(result), do: wait_for_job(result, 0)

  defp wait_for_job(_result, attempts) when attempts > @max_job_wait_seconds do
    {:error, "exceeded max job wait time #{@max_job_wait_seconds}"}
  end

  defp wait_for_job(%{"status" => %{"state" => "RUNNING"}, "jobReference" => %{"jobId" => id}}, n) do
    :timer.sleep(1000)
    get("jobs/#{id}") |> wait_for_job(n + 1)
  end

  defp wait_for_job(%{"status" => %{"errorResult" => %{"message" => msg}}}, _n) do
    {:error, msg}
  end

  defp wait_for_job(%{"status" => %{"state" => "DONE"}, "statistics" => %{"load" => stats}}, _n) do
    case stats do
      %{"badRecords" => "0", "outputRows" => r} -> {:ok, "loaded #{r} rows"}
      %{"badRecords" => b, "outputRows" => r} -> {:ok, "loaded #{r} rows (#{b} bad)"}
    end
  end
end
