defmodule Mix.Tasks.Feeder.Sync do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Manually run the Feeder data refresh"

  @podlabel "Feeder.SyncPodcasts"
  @eplabel "Feeder.SyncEpisodes"

  @lock "lock.feeder.sync"
  @lock_ttl 50
  @success_ttl 10

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    lock = Enum.member?(args, "--lock") || Enum.member?(args, "-l")
    force = Enum.member?(args, "--force") || Enum.member?(args, "-f")
    all = force || Enum.member?(args, "--all") || Enum.member?(args, "-a")

    pod_since = if force, do: nil, else: Castle.Podcast.max_updated_at()
    ep_since = if force, do: nil, else: Castle.Episode.max_updated_at()

    if lock do
      lock("#{@lock}.podcasts", @lock_ttl, @success_ttl, do: sync_podcasts(pod_since, all))
      lock("#{@lock}.episodes", @lock_ttl, @success_ttl, do: sync_episodes(ep_since, all))
    else
      sync_podcasts(pod_since, all)
      sync_episodes(ep_since, all)
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
    Logger.info("#{label}.all from #{Env.get(:feeder_host)}")
    nil
  end

  defp log_start(dtim, label) do
    Logger.info("#{label}.since(#{dtim}) from #{Env.get(:feeder_host)}")
    dtim
  end

  defp log_end({:ok, 0, 0, 0}, label) do
    Logger.info("#{label} no changes")
  end

  defp log_end({:ok, created, updated, remaining}, label) do
    Logger.info("#{label} #{created} created / #{updated} updated / #{remaining} remaining")
    if remaining > 0, do: :remaining, else: :done
  end

  defp log_end({:error, "" <> err}, label) do
    Logger.error("#{label} #{inspect(err)}")
    :error
  end
end
