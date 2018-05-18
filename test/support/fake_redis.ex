defmodule Castle.FakeRedis do
  @behaviour Castle.Redis

  def cached(_key, _ttl, work_fn), do: work_fn.()

  def podcast_increments(_id, _intv), do: {nil, nil}

  def podcast_trends_cache(_id, work_fn), do: work_fn.()

  def episode_increments(_guid, _intv), do: {nil, nil}

  def episode_trends_cache(_guid, work_fn), do: work_fn.()
end
