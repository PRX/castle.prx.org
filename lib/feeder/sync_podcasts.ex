defmodule Feeder.SyncPodcasts do
  def sync(dtim, root) do
    case get_podcasts(root, dtim) do
      {:error, err} ->
        {:error, err}

      {_ok_or_partial, total, docs} ->
        {created, updated} = update_podcasts(docs)
        {:ok, created, updated, total - created - updated}
    end
  end

  defp get_podcasts(root, nil), do: Feeder.Api.podcasts(root)
  defp get_podcasts(root, dtim), do: Feeder.Api.podcasts(root, Timex.shift(dtim, milliseconds: 1))

  defp update_podcasts(podcast_docs) do
    created_count =
      podcast_docs
      |> Enum.map(&update_podcast/1)
      |> Enum.count(&(&1 == :created))

    {created_count, length(podcast_docs) - created_count}
  end

  defp update_podcast(doc) do
    case Castle.Repo.get(Castle.Podcast, doc["id"]) do
      nil ->
        Castle.Podcast.from_feeder(doc)
        :created

      podcast ->
        Castle.Podcast.from_feeder(podcast, doc)
        :updated
    end
  end
end
