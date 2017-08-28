defmodule Castle.RedisPartitionCacheTest do
  use Castle.RedisCase, async: true

  @moduletag :redis

  import Castle.Redis.PartitionCache

  @prefix "partition.cache.test"

  setup do
    redis_clear("#{@prefix}*")
    {:ok, dtim1, _} = DateTime.from_iso8601("2017-03-22T02:45:00Z")
    {:ok, dtim2, _} = DateTime.from_iso8601("2017-03-29T02:46:00Z")
    {:ok, dtim3, _} = DateTime.from_iso8601("2017-03-30T02:47:00Z")
    [date1: dtim1, date2: dtim2, date3: dtim3]
  end

  test "combines a result list", %{date1: date1, date2: date2, date3: date3} do
    {result, _meta} = partition @prefix, [
      fn() -> {date1, ["a", "b"], %{}} end,
      fn(_date) -> {["b", "c", "d"], %{}} end,
      fn() -> {date2, [], %{}} end,
      fn(_date) -> {date3, ["b"], %{}} end]
    assert length(result) == 6
    assert result == ["a", "b", "b", "c", "d", "b"]
  end

  test "custom combines result list", %{date1: date1, date2: date2, date3: date3} do
    {result, _meta} = partition @prefix, fn(parts) -> Enum.uniq(parts) end, [
      fn() -> {date1, ["a", "b"], %{}} end,
      fn(_date) -> {["b", "c", "d"], %{}} end,
      fn() -> {date2, [], %{}} end,
      fn(_date) -> {date3, ["b"], %{}} end]
    assert length(result) == 4
    assert result == ["a", "b", "c", "d"]
  end

  test "combines the metadata", %{date1: date1, date2: date2} do
    {_result, meta} = partition @prefix, [
      fn() -> {date1, [], %{cached: true}} end,
      fn(_date) -> {date2, [], %{cached: true, megabytes: 1, total: 2}} end,
      fn(_date) -> {nil, [], %{bytes: 3, cached: false, megabytes: 999, total: 1}} end]
    assert meta.cached == false
    assert meta.bytes == 3
    assert meta.megabytes == 1000
    assert meta.total == 3
  end

  test "caches function results in redis", %{date1: date1, date2: date2} do
    {data1, _} = partition @prefix, [
      fn() -> {date1, ["foo1"], %{}} end,
      fn(_date) -> {date2, ["foo2"], %{}} end,
      fn(_date) -> {["foo3"], %{}} end]
    assert redis_count("#{@prefix}.*") == 3
    assert data1 == ["foo1", "foo2", "foo3"]

    {data2, _} = partition @prefix, [
      fn() -> {date1, ["bar1"], %{}} end,
      fn(_date) -> {date2, ["bar2"], %{}} end,
      fn(_date) -> {["bar3"], %{}} end]
    assert data2 == ["foo1", "foo2", "foo3"]
  end

  test "passes dates between partitions", %{date1: date1, date2: date2, date3: date3} do
    {data, _} = partition @prefix, [
      fn() -> {date1, ["foo1"], %{}} end,
      fn(date) ->
        assert date == date1
        {date2, ["foo2"], %{}}
      end,
      fn(date) ->
        assert date == date2
        {nil, ["foo3"], %{}}
      end]
    assert data == ["foo1", "foo2", "foo3"]

    # expire part 2, which should re-run 2 and 3
    [_, key, _] = redis_keys("#{@prefix}.*") |> Enum.sort()
    redis_clear(key)

    {data, _} = partition @prefix, [
      fn() -> throw("should not have gotten here") end,
      fn(date) ->
        assert date == date1
        {date3, ["bar2"], %{}}
      end,
      fn(date) ->
        assert date == date3
        {nil, ["bar3"], %{}}
      end]
    assert data == ["foo1", "bar2", "bar3"]
  end

  test "expires partitions", %{date1: date1, date2: date2, date3: date3} do
    {data, _} = partition @prefix, [
      {20, fn() -> {date1, ["foo1"], %{}} end},
      {1, fn(_) -> {date2, ["foo2"], %{}} end},
      {0, fn(_) -> {date3, ["foo3"], %{}} end},
      fn(_) -> {nil, ["foo4"], %{}} end]
    assert data == ["foo1", "foo2", "foo3", "foo4"]
    assert redis_count("#{@prefix}.*") == 4

    {data, _} = partition @prefix, [
      fn() -> {date1, ["bar1"], %{}} end,
      fn(_) -> {date2, ["bar2"], %{}} end,
      fn(_) -> {date3, ["bar3"], %{}} end,
      fn(_) -> {nil, ["bar4"], %{}} end]
    assert data == ["foo1", "foo2", "bar3", "bar4"]
    assert redis_count("#{@prefix}.*") == 4

    {data, _} = partition @prefix, [
      fn() -> throw("should not have gotten here") end,
      fn() -> throw("should not have gotten here") end,
      fn() -> throw("should not have gotten here") end,
      fn() -> throw("should not have gotten here") end]
    assert data == ["foo1", "foo2", "bar3", "bar4"]
    assert redis_count("#{@prefix}.*") == 4
  end
end
