defmodule Mix.Tasks.Bigquery.Sync.Agentnames do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Sync prx-podagent tags to BigQuery"
  @lock "lock.bigquery.sync.agentnames"
  @lock_ttl 120
  @success_ttl 30
  @url "https://raw.githubusercontent.com/PRX/prx-podagent/main/db/agents.lock.json"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    lock = Enum.member?(args, "--lock") || Enum.member?(args, "-l")

    if lock do
      lock(@lock, @lock_ttl, @success_ttl, do: sync_agentnames())
    else
      sync_agentnames()
    end
  end

  defp sync_agentnames do
    case get_podagent_tags() do
      {:ok, tags} ->
        data = Enum.map(tags, &Jason.encode!/1) |> Enum.join("\n")
        dest = "#{Env.get(:bq_dataset)}.agentnames"
        Logger.info("BigQuery.Sync.Agentnames reload: #{dest} with #{length(tags)} rows")

        case BigQuery.Base.Load.reload("agentnames", data) do
          {:ok, msg} -> Logger.info("BigQuery.Sync.Agentnames success: #{msg}")
          {:error, msg} -> Logger.error("BigQuery.Sync.Agentnames error: #{msg}")
        end

      {:error, msg} ->
        Logger.error("BigQuery.Sync.Agentnames error: #{msg}")
    end
  end

  defp get_podagent_tags do
    case HTTPoison.get(@url) do
      {:ok, %{status_code: 200, body: body}} -> Jason.decode(body) |> format_tags()
      {:ok, %{status_code: code}} -> {:error, "got #{code} from podagents"}
      err -> {:error, inspect(err)}
    end
  end

  defp format_tags({:ok, json}) do
    tags = Map.get(json, "tags", [])
    formatted = Enum.map(tags, fn {id, tag} -> %{agentname_id: id, tag: tag} end)
    {:ok, formatted}
  end

  defp format_tags(err), do: err
end
