defmodule Castle.RedisIntervalCacheSetterTest do
  use Castle.RedisCase, async: false
  use Castle.TimeHelpers

  @moduletag :redis

  import Mock
  alias Castle.Redis.Conn, as: Conn
  alias Castle.Redis.Interval.Keys, as: Keys
  alias Castle.Redis.Interval.Setter, as: Setter

  @prefix "interval.cache.setter.test"

  setup do
    redis_clear("#{@prefix}*")
    from = get_dtim("2017-03-22T01:15:00Z")
    to = get_dtim("2017-03-22T02:15:00Z")
    [from: from, to: to]
  end

  test "sets ttl according to the time" do
    with_mock Timex, [:passthrough], [now: fn() -> get_dtim("2017-03-22T01:15:00Z") end] do
      assert Setter.interval_ttl(get_dtim("2017-03-22T00:15:00Z")) == 0
      assert Setter.interval_ttl(get_dtim("2017-03-22T00:16:00Z")) == 300
      assert Setter.interval_ttl(get_dtim("2017-03-22T01:14:00Z")) == 300
      assert Setter.interval_ttl(get_dtim("2017-03-22T01:15:00Z")) == 300
      assert Setter.interval_ttl(get_dtim("2017-03-22T02:20:00Z")) == 300
    end
  end

  test "sets empty counts", %{from: from, to: to} do
    assert redis_count("#{@prefix}*") == 0
    Setter.set(@prefix, from, to, %{})
    assert redis_count("#{@prefix}*") == 1
    assert Conn.command(["TTL", List.first(redis_keys("#{@prefix}*"))]) == -1
  end

  test "sets a ttl on the key close to now", %{from: from, to: to} do
    with_mock Timex, [:passthrough], [now: fn() -> get_dtim("2017-03-22T01:15:00Z") end] do
      Setter.set(@prefix, from, to, %{})
      assert Conn.command(["TTL", List.first(redis_keys("#{@prefix}*"))]) == 300
    end
  end

  test "sets values", %{from: from, to: to} do
    Setter.set(@prefix, from, to, %{1 => 123, "foo" => "bar"})
    assert Conn.hget(Keys.key(@prefix, from), 1) == 123
    assert Conn.hget(Keys.key(@prefix, from), "foo") == "bar"
    assert Conn.hget(Keys.key(@prefix, to), 1) == nil
    assert redis_count("#{@prefix}*") == 1
  end
end
