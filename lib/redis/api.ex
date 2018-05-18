defmodule Castle.Redis.Api do
  @behaviour Castle.Redis

  defdelegate cached(key, ttl, work_fn),
    to: Castle.Redis.ResponseCache,
    as: :cached

  defdelegate podcast_increments(id, interval),
    to: Castle.Redis.Increments,
    as: :get_podcast

  defdelegate podcast_trends_cache(id, work_fn),
    to: Castle.Redis.TrendsCache,
    as: :podcast_trends

  defdelegate episode_increments(id, interval),
    to: Castle.Redis.Increments,
    as: :get_episode

    defdelegate episode_trends_cache(id, work_fn),
      to: Castle.Redis.TrendsCache,
      as: :episode_trends
end
