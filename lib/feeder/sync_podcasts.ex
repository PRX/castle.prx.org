defmodule Feeder.SyncPodcasts do
  require Logger

  def all do
    Logger.info "Feeder.SyncPodcasts.all from #{Env.get(:feeder_host)}"
    Feeder.Api.podcasts(nil) |> update_podcasts()
  end

  def since(nil), do: all()
  def since(dtim) do
    Logger.info "Feeder.SyncPodcasts.since(#{dtim}) from #{Env.get(:feeder_host)}"
    Timex.shift(dtim, milliseconds: 1) |> Feeder.Api.podcasts() |> update_podcasts()
  end

  defp update_podcasts(podcast_docs) do
    Enum.map(podcast_docs, fn(doc) ->
      Castle.Repo.get(Castle.Podcast, doc["id"]) |> update_podcast(doc)
      doc["id"]
    end)
  end

  defp update_podcast(nil, doc) do
    podcast = struct!(Castle.Podcast, build_changeset(doc))
    Logger.info "Feeder.SyncPodcasts.create(#{podcast.id}) #{podcast.name}"
    Castle.Repo.insert!(podcast)
  end
  defp update_podcast(podcast, doc) do
    changes = build_changeset(doc)
    if Timex.compare(changes.updated_at, podcast.updated_at) >= 0 do
      Logger.info "Feeder.SyncPodcasts.update(#{podcast.id}) #{podcast.name}"
      Castle.Podcast.changeset(podcast, changes) |> Castle.Repo.update!
    end
  end

  defp build_changeset(doc) do
    %{
      id: doc["id"],
      account_id: account_id(doc["prxAccountUri"]),
      name: doc["title"],
      created_at: parse_dtim(doc["createdAt"]),
      updated_at: parse_dtim(doc["updatedAt"]),
      published_at: parse_dtim(doc["publishedAt"]),
    }
  end

  defp account_id("/api/v1/accounts/" <> id), do: String.to_integer(id)
  defp account_id(_any), do: nil

  defp parse_dtim(nil), do: nil
  defp parse_dtim(dtim_str) do
    {:ok, dtim} = Timex.parse(dtim_str, "{ISO:Extended:Z}")
    dtim
  end
end
