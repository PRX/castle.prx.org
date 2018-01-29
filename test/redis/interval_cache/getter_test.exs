defmodule Castle.RedisIntervalCacheGetterTest do
  use Castle.RedisCase, async: false
  use Castle.TimeHelpers

  @moduletag :redis

  import Mock
  alias Castle.Redis.Conn, as: Conn
  alias Castle.Redis.Interval.Keys, as: Keys
  alias Castle.Redis.Interval.Getter, as: Getter

  @prefix "interval.cache.getter.test"

  setup do
    redis_clear("#{@prefix}*")
    from = get_dtim("2017-03-22T01:00:00Z")
    to = get_dtim("2017-03-22T05:00:00Z")
    rollup = BigQuery.TimestampRollups.Hourly
    keys = Keys.keys(@prefix, rollup.range(from, to))
    [from: from, to: to, rollup: rollup, keys: keys]
  end

  test "hits the entire range", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "field1", 11)
    Conn.hset(Enum.at(keys, 1), "field1", 22)
    Conn.hset(Enum.at(keys, 2), "field1", 33)
    Conn.hset(Enum.at(keys, 3), "field1", 44)
    {hits, new_from} = Getter.get(@prefix, "field1", from, to, rollup)

    assert length(hits) == 4
    assert new_from == nil
    assert_time Enum.at(hits, 0).time, "2017-03-22T01:00:00Z"
    assert_time Enum.at(hits, 1).time, "2017-03-22T02:00:00Z"
    assert_time Enum.at(hits, 2).time, "2017-03-22T03:00:00Z"
    assert_time Enum.at(hits, 3).time, "2017-03-22T04:00:00Z"
    assert Enum.at(hits, 0).count == 11
    assert Enum.at(hits, 1).count == 22
    assert Enum.at(hits, 2).count == 33
    assert Enum.at(hits, 3).count == 44
  end

  test "misses a partial range", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "field1", 11)
    Conn.hset(Enum.at(keys, 1), "field1", 22)
    Conn.hset(Enum.at(keys, 3), "field1", 44)
    {hits, new_from} = Getter.get(@prefix, "field1", from, to, rollup)

    assert length(hits) == 2
    assert_time new_from, "2017-03-22T03:00:00Z"
    assert_time Enum.at(hits, 0).time, "2017-03-22T01:00:00Z"
    assert_time Enum.at(hits, 1).time, "2017-03-22T02:00:00Z"
    assert Enum.at(hits, 0).count == 11
    assert Enum.at(hits, 1).count == 22
  end

  test "misses the entire range", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 1), "field1", 22)
    Conn.hset(Enum.at(keys, 2), "field1", 33)
    Conn.hset(Enum.at(keys, 3), "field1", 44)
    {hits, new_from} = Getter.get(@prefix, "field1", from, to, rollup)
    assert hits == []
    assert_time new_from, "2017-03-22T01:00:00Z"
  end

  test "interprets hash-field misses as 0", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "field1", 11)
    Conn.hset(Enum.at(keys, 1), "field2", 99)
    Conn.hset(Enum.at(keys, 3), "field1", 44)
    {hits, new_from} = Getter.get(@prefix, "field1", from, to, rollup)

    assert length(hits) == 2
    assert_time new_from, "2017-03-22T03:00:00Z"
    assert_time Enum.at(hits, 0).time, "2017-03-22T01:00:00Z"
    assert_time Enum.at(hits, 1).time, "2017-03-22T02:00:00Z"
    assert Enum.at(hits, 0).count == 11
    assert Enum.at(hits, 1).count == 0
  end

  test "hits all 0s", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "field2", 99)
    Conn.hset(Enum.at(keys, 1), "field2", 99)
    Conn.hset(Enum.at(keys, 2), "field2", 99)
    Conn.hset(Enum.at(keys, 3), "field2", 99)
    {hits, new_from} = Getter.get(@prefix, "field1", from, to, rollup)
    assert length(hits) == 4
    assert new_from == nil
  end

  test "assumes 0 on misses within a few seconds of now", %{from: from, to: to, rollup: rollup, keys: keys} do
    Conn.hset(Enum.at(keys, 0), "field1", 11)
    Conn.hset(Enum.at(keys, 1), "field1", 22)
    Conn.hset(Enum.at(keys, 2), "field1", 33)
    hits_at_time = fn(time) ->
      with_mock Timex, [:passthrough], [now: fn() -> get_dtim(time) end] do
        {hits, _new_from} = Getter.get(@prefix, "field1", from, to, rollup)
        {length(hits), List.last(hits).count}
      end
    end
    assert hits_at_time.("2017-03-22T05:00:00Z") == {3, 33}
    assert hits_at_time.("2017-03-22T04:00:00Z") == {4, 0}
    assert hits_at_time.("2017-03-22T04:00:29Z") == {4, 0}
    assert hits_at_time.("2017-03-22T04:00:31Z") == {3, 33}
    assert hits_at_time.("2017-03-22T00:00:00Z") == {4, 0}
  end
end
