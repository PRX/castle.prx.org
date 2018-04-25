defmodule Mix.Tasks.Feeder.Sync do
  use Mix.Task

  require Logger

  @shortdoc "Manually run the Feeder data refresh"
  @podlabel "Feeder.SyncPodcasts"
  @eplabel "Feeder.SyncEpisodes"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)
    cond do
      Enum.member?(args, "--force") || Enum.member?(args, "-f") ->
        sync_podcasts(nil, true)
        sync_episodes(nil, true)
      Enum.member?(args, "--all") || Enum.member?(args, "-a") ->
        sync_podcasts(Castle.Podcast.max_updated_at(), true)
        sync_episodes(Castle.Episode.max_updated_at(), true)
      true ->
        sync_podcasts(Castle.Podcast.max_updated_at(), false)
        sync_episodes(Castle.Episode.max_updated_at(), false)
    end
  end

  defp sync_podcasts(since, process_all) do
    status = since |> log_start(@podlabel) |> Feeder.SyncPodcasts.sync() |> log_end(@podlabel)
    if status == :remaining && process_all do
      sync_podcasts(Castle.Podcast.max_updated_at(), process_all)
    end
  end

  defp sync_episodes(since, process_all) do
    status = since |> log_start(@eplabel) |> Feeder.SyncEpisodes.sync() |> log_end(@eplabel)
    if status == :remaining && process_all do
      sync_episodes(Castle.Episode.max_updated_at(), process_all)
    end
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
    if remaining > 0, do: :remaining, else: :done
  end
  defp log_end({:error, err}, label) do
    Logger.error "#{label} #{err}"
    :error
  end
end
