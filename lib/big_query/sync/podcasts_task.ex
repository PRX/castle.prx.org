defmodule Mix.Tasks.Bigquery.Sync.Podcasts do
  use Mix.Task
  require Logger

  @shortdoc "Sync feeder podcasts to BigQuery"

  def run(_args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

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
