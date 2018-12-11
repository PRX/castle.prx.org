defmodule Insights.WeeklySnapshot do
  import Ecto.Query

  def new(podcast_ids) when is_list(podcast_ids) do
    %{
      podcasts: podcasts(podcast_ids),
      new_episodes: new_episodes(podcast_ids)
    }
  end

  def podcasts(podcast_ids) do
    query = from p in Castle.Podcast,
      where: p.id in ^podcast_ids,
      order_by: [asc: :title]
    Castle.Repo.all(query)
  end

  def new_episodes(podcast_ids) do
    podcast_ids
    |> Enum.flat_map(fn(podcast_id) ->
      Timex.now
      |> Timex.shift(days: -7)
      |> Castle.Episode.created_after
      |> Castle.Repo.all
    end)
  end

end
