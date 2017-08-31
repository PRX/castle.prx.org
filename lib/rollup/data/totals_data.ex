defmodule Castle.Rollup.Data.Totals do
  import Castle.Rollup.Jobs.Totals

  # TODO: this is real ugly. Just trying to combine/sort the episode maps
  def podcasts() do
    {result, _meta} = get()
    result
    |> Enum.map(&(Map.put(&1, :feeder_episodes, [&1.feeder_episode])))
    |> Enum.map(&(Map.delete(&1, :feeder_episode)))
    |> Enum.group_by(&(&1.feeder_podcast))
    |> Enum.map(fn({_podcast_id, episodes}) ->
      Enum.reduce(episodes, %{}, fn(episode, acc) ->
        Map.merge(acc, episode, fn(k, v1, v2) ->
          case k do
            :count -> v1 + v2
            :feeder_episodes -> Enum.sort(v1 ++ v2)
            _ -> v2
          end
        end)
      end)
    end)
    |> Enum.sort(&(&1.feeder_podcast < &2.feeder_podcast))
  end

  def podcast(id) do
    podcasts() |> Enum.find(&(&1.feeder_podcast == id))
  end

  def episodes() do
    {result, _meta} = get()
    result |> Enum.sort(&(&1.feeder_episode < &2.feeder_episode))
  end

  def episode(guid) do
    episodes() |> Enum.find(&(&1.feeder_episode == guid))
  end

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
