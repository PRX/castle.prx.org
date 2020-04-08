defmodule Feeder.SyncEpisodes do
  def sync(dtim, root) do
    case get_episodes(root, dtim) do
      {:error, err} ->
        {:error, err}

      {_ok_or_partial, total, docs} ->
        {created, updated} = with_podcast(docs) |> update_episodes()
        {:ok, created, updated, total - created - updated}
    end
  end

  defp get_episodes(root, nil), do: Feeder.Api.episodes(root)
  defp get_episodes(root, dtim), do: Feeder.Api.episodes(root, Timex.shift(dtim, milliseconds: 1))

  defp with_podcast(docs) do
    Enum.filter(docs, fn doc -> PrxAccess.link?(doc, "prx:podcast") end)
  end

  defp update_episodes(episode_docs) do
    created_count =
      episode_docs
      |> Enum.map(&update_episode/1)
      |> Enum.count(&(&1 == :created))

    {created_count, length(episode_docs) - created_count}
  end

  defp update_episode(doc) do
    case Castle.Repo.get(Castle.Episode, doc["id"]) do
      nil ->
        Castle.Episode.from_feeder(doc)
        :created

      episode ->
        Castle.Episode.from_feeder(episode, doc)
        :updated
    end
  end
end
