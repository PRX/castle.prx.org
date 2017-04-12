defmodule Castle.RedisCachedResponseTest do
  use Castle.RedisCase, async: true

  import Castle.Redis.CachedResponse

  setup do
    Castle.Redis.Conn.del("some_cache_key")
    []
  end

  @tag :redis
  test "caches responses but not metadata" do
    data = %{some: "data"}
    meta = %{the: "meta"}

    {d, m} = cached("some_cache_key", 1, fn() -> {data, meta} end)
    assert d == %{some: "data"}
    assert m == %{the: "meta"}

    {d, m} = cached("some_cache_key", 1, fn() -> {data, meta} end)
    assert d == %{some: "data"}
    assert m == %{cached: true}
  end
end
