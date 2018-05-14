defmodule Castle.FakeRedis do
  @behaviour Castle.Redis

  def cached(_key, _ttl, work_fn), do: work_fn.()

  def podcast_increments(_id, _intv), do: {nil, nil}

  def episode_increments(_guid, _intv), do: {nil, nil}
end
