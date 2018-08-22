defmodule Castle.Redis.Api do
  @behaviour Castle.Redis

  defdelegate cached(key, ttl, work_fn),
    to: Castle.Redis.ResponseCache,
    as: :cached

  defdelegate podcast_increments(id, interval),
    to: Castle.Redis.Increments,
    as: :get_podcast

  defdelegate podcast_totals_cache(id, work_fn),
    to: Castle.Redis.TotalsCache,
    as: :podcast_totals

  defdelegate episode_increments(id, interval),
    to: Castle.Redis.Increments,
    as: :get_episode

    defdelegate episode_totals_cache(id, work_fn),
      to: Castle.Redis.TotalsCache,
      as: :episode_totals
end
