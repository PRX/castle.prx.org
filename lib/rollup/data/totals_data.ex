defmodule Castle.Rollup.Data.Totals do
  import Castle.Rollup.Jobs.Totals

  def podcast_downloads(podcast_id) do
    find_count &(&1.feeder_podcast == podcast_id)
  end

  def episode_downloads(episode_guid) do
    find_count &(&1.feeder_episode == episode_guid)
  end

  defp find_count(finder_fn) do
    {result, _meta} = get()
    result
    |> Enum.filter(finder_fn)
    |> Enum.map(&(&1.count))
    |> Enum.sum()
  end
end
