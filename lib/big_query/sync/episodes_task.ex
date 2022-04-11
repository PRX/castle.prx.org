defmodule Mix.Tasks.Bigquery.Sync.Episodes do
  use Mix.Task
  require Logger

  @shortdoc "Sync feeder episodes to BigQuery"

  def run(_args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    fields = ~w(
      id podcast_id title subtitle image_url
      created_at updated_at published_at released_at deleted_at
      segment_count audio_version keywords
    )

    rows = Enum.map(Castle.Episode.all(), &episode_row(&1, fields))
    data = Enum.join(rows, "\n")

    dest = "#{Env.get(:bq_dataset)}.episodes"
    Logger.info("BigQuery.Sync.Episodes reload: #{dest} with #{length(rows)} rows")

    case BigQuery.Base.Load.reload("episodes", data) do
      {:ok, msg} -> Logger.info("BigQuery.Sync.Episodes success: #{msg}")
      {:error, msg} -> Logger.error("BigQuery.Sync.Episodes error: #{msg}")
    end
  end

  defp episode_row(%Castle.Episode{} = episode, fields) do
    episode
    |> Map.from_struct()
    |> Map.new(fn {k, v} -> {to_string(k), v} end)
    |> Map.take(fields)
    |> Jason.encode!()
  end
end
