defmodule Castle.RedisIntervalCacheTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  import Castle.Redis.IntervalCache
  alias Castle.Redis.Conn, as: Conn
  alias Castle.Redis.Interval.Keys, as: Keys
  alias BigQuery.TimestampRollups.Hourly, as: Hourly

  @prefix "interval.cache.test"

  setup do
    redis_clear("#{@prefix}*")
    from = get_dtim("2017-03-22T01:00:00Z")
    to = get_dtim("2017-03-22T05:00:00Z")
    intv = %BigQuery.Interval{from: from, to: to, rollup: Hourly, bucket: Hourly}
    keys = Keys.keys("#{@prefix}.#{intv.rollup.name()}", intv.rollup.range(from, to))
    [interval: intv, keys: keys]
  end

  test "misses the whole interval", %{interval: intv} do
    {data, meta} = interval(@prefix, intv, "foobar", &test_work_fn/1)
    assert redis_count("#{@prefix}*") == 4
    assert meta.cache_hits == 0
    assert length(data) == 4
    assert_time data, 0, "2017-03-22T01:00:00Z"
    assert_time data, 1, "2017-03-22T02:00:00Z"
    assert_time data, 2, "2017-03-22T03:00:00Z"
    assert_time data, 3, "2017-03-22T04:00:00Z"
    assert Enum.at(data, 0).count == 13
    assert Enum.at(data, 1).count == 0
    assert Enum.at(data, 2).count == 0
    assert Enum.at(data, 3).count == 43

    {data2, meta2} = interval(@prefix, intv, "foobar", &test_work_fn/1)
    assert redis_count("#{@prefix}*") == 4
    assert meta2.cache_hits == 4
    assert meta2.cached == true
    assert data2 == data
  end

  test "partially hits the cache", %{interval: intv, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "foobar", 11)
    Conn.hset(Enum.at(keys, 1), "foobar", 22)
    Conn.hset(Enum.at(keys, 3), "foobar", 44)
    {data, meta} = interval(@prefix, intv, "foobar", &test_work_fn/1)
    assert redis_count("#{@prefix}*") == 4
    assert meta.cache_hits == 2
    assert length(data) == 4
    assert_time data, 0, "2017-03-22T01:00:00Z"
    assert_time data, 1, "2017-03-22T02:00:00Z"
    assert_time data, 2, "2017-03-22T03:00:00Z"
    assert_time data, 3, "2017-03-22T04:00:00Z"
    assert Enum.at(data, 0).count == 11
    assert Enum.at(data, 1).count == 22
    assert Enum.at(data, 2).count == 0
    assert Enum.at(data, 3).count == 43
  end

  test "hits cache 0s", %{interval: intv, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "nothing", 99)
    Conn.hset(Enum.at(keys, 1), "foobar", 22)
    Conn.hset(Enum.at(keys, 2), "nothing", 99)
    {data, meta} = interval(@prefix, intv, "foobar", &test_work_fn/1)
    assert redis_count("#{@prefix}*") == 4
    assert meta.cache_hits == 3
    assert length(data) == 4
    assert_time data, 0, "2017-03-22T01:00:00Z"
    assert_time data, 1, "2017-03-22T02:00:00Z"
    assert_time data, 2, "2017-03-22T03:00:00Z"
    assert_time data, 3, "2017-03-22T04:00:00Z"
    assert Enum.at(data, 0).count == 0
    assert Enum.at(data, 1).count == 22
    assert Enum.at(data, 2).count == 0
    assert Enum.at(data, 3).count == 43
  end

  defp test_work_fn(intv) do
    lookup = %{
      "2017-03-22T01:00:00Z" => %{1 => 11, 2 => 12, "foobar" => 13},
      "2017-03-22T02:00:00Z" => %{1 => 21, 2 => 22},
      "2017-03-22T03:00:00Z" => %{},
      "2017-03-22T04:00:00Z" => %{"foobar" => 43},
    }
    data = Enum.map intv.rollup.range(intv.from, intv.to), fn(dtim) ->
      {dtim, Map.get(lookup, format_dtim(dtim))}
    end
    {data, %{meta: "data"}}
  end
end
