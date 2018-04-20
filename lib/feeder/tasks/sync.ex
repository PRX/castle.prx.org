defmodule Mix.Tasks.Feeder.Sync do
  use Mix.Task

  require Logger

  @shortdoc "Manually run the Feeder data refresh"

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    case Feeder.SyncPodcasts.since(Castle.Podcast.max_updated_at) do
      [] -> Logger.info "No changes!"
      ids -> Logger.info "Changed: [#{Enum.join(ids, ", ")}]"
    end
  end
end
