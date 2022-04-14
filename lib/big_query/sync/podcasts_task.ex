defmodule Mix.Tasks.Bigquery.Sync.Podcasts do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Sync feeder podcasts to BigQuery"
  @lock "lock.bigquery.sync.podcasts"
  @lock_ttl 60
  @success_ttl 30

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    lock = Enum.member?(args, "--lock") || Enum.member?(args, "-l")

    if lock do
      lock(@lock, @lock_ttl, @success_ttl, do: sync_podcasts())
    else
      sync_podcasts()
    end
  end

  defp sync_podcasts do
    fields = ~w(
      id account_id title subtitle image_url
      created_at updated_at published_at deleted_at
    )

    rows = Enum.map(Castle.Podcast.all(), &podcast_row(&1, fields))
    data = Enum.join(rows, "\n")

    dest = "#{Env.get(:bq_dataset)}.podcasts"
    Logger.info("BigQuery.Sync.Podcasts reload: #{dest} with #{length(rows)} rows")

    case BigQuery.Base.Load.reload("podcasts", data) do
      {:ok, msg} -> Logger.info("BigQuery.Sync.Podcasts success: #{msg}")
      {:error, msg} -> Logger.error("BigQuery.Sync.Podcasts error: #{msg}")
    end
  end

  defp podcast_row(%Castle.Podcast{} = podcast, fields) do
    podcast
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> Map.take(fields)
    |> Jason.encode!()
  end
end
