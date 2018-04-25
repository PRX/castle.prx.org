defmodule Mix.Tasks.Feeder.Sync do
  use Mix.Task

  require Logger

  @shortdoc "Manually run the Feeder data refresh"

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:castle)
    Castle.Podcast.max_updated_at()
      |> log_start("Feeder.SyncPodcasts")
      |> Feeder.SyncPodcasts.sync()
      |> log_end("Feeder.SyncPodcasts")
    Castle.Episode.max_updated_at()
      |> log_start("Feeder.SyncEpisodes")
      |> Feeder.SyncEpisodes.sync()
      |> log_end("Feeder.SyncEpisodes")
  end

  defp log_start(nil, label) do
    Logger.info "#{label}.all from #{Env.get(:feeder_host)}"
    nil
  end
  defp log_start(dtim, label) do
    Logger.info "#{label}.since(#{dtim}) from #{Env.get(:feeder_host)}"
    dtim
  end

  defp log_end({:ok, 0, 0, 0}, label) do
    Logger.info "#{label} no changes"
  end
  defp log_end({:ok, created, updated, remaining}, label) do
    Logger.info "#{label} #{created} created / #{updated} updated / #{remaining} remaining"
  end
end
