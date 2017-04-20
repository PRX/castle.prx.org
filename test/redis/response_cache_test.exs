defmodule Castle.RedisResponseCacheTest do
  use Castle.RedisCase, async: true

  @moduletag :redis

  import Castle.Redis.ResponseCache

  setup do
    redis_clear("response_cache_test*")
    []
  end

  test "caches responses but not metadata" do
    data = %{some: "data"}
    meta = %{the: "meta"}

    {d, m} = cached("response_cache_test", 1, fn() -> {data, meta} end)
    assert d == %{some: "data"}
    assert m == %{the: "meta"}

    {d, m} = cached("response_cache_test", 1, fn() -> {data, meta} end)
    assert d == %{some: "data"}
    assert m == %{cached: true}
  end
end
