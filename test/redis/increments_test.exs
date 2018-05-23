defmodule Castle.RedisIncrementsTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  alias Castle.Redis.Increments, as: Increments
  alias Castle.Redis.Conn, as: Conn

  @prefix "testincr"

  setup do
    redis_clear("#{@prefix}*")
    [
      intv: %Castle.Interval{
        from: get_dtim("2018-05-12T00:00:00"),
        to: get_dtim("2018-05-14T00:00:00"),
        bucket: Castle.Bucket.Daily}
    ]
  end

  test "uses a cache boundary 15 minutes in the past" do
    assert_time cache_boundary("2018-05-13T00:00:00"), "2018-05-12T23:00:00Z"
    assert_time cache_boundary("2018-05-13T00:14:59"), "2018-05-12T23:00:00Z"
    assert_time cache_boundary("2018-05-13T00:15:00"), "2018-05-13T00:00:00Z"
    assert_time cache_boundary("2018-05-13T01:14:00"), "2018-05-13T00:00:00Z"
  end

  test "returns nil if there is no cached data", %{intv: intv} do
    {cached, new_intv} = get_increments(intv, "2018-05-13T12:00:00")
    assert cached == nil
    assert new_intv == nil
  end

  test "returns nil if interval starts after cached data", %{intv: intv} do
    Conn.hset("#{@prefix}.HOUR.2018-05-11T23:00:00Z", 123, 777)
    {cached, new_intv} = get_increments(intv, "2018-05-12T00:00:01")
    assert cached == nil
    assert new_intv == nil
  end

  test "returns nil if interval is in the past", %{intv: intv} do
    Conn.hset("#{@prefix}.HOUR.2018-05-13T14:00:00Z", 123, 999)
    {cached, new_intv} = get_increments(intv, "2018-05-13T12:00:00")
    assert cached == nil
    assert new_intv == nil
  end

  test "returns cached values and a new interval", %{intv: intv} do
    Conn.hset("#{@prefix}.HOUR.2018-05-13T10:00:00Z", 123, 777)
    Conn.hset("#{@prefix}.HOUR.2018-05-13T11:00:00Z", 123, 888)
    Conn.hset("#{@prefix}.HOUR.2018-05-13T11:00:00Z", 456, 888)
    Conn.hset("#{@prefix}.HOUR.2018-05-13T12:00:00Z", 123, 999)
    {cached, new_intv} = get_increments(intv, "2018-05-13T12:00:01")
    assert length(cached) == 2
    assert Enum.at(cached, 0).count == 888
    assert Enum.at(cached, 1).count == 999
    assert_time Enum.at(cached, 0).time, "2018-05-13T11:00:00Z"
    assert_time Enum.at(cached, 1).time, "2018-05-13T12:00:00Z"
    assert_time new_intv.from, "2018-05-12T00:00:00Z"
    assert_time new_intv.to, "2018-05-13T11:00:00Z"
    assert new_intv.bucket.name == "DAY"
  end

  test "returns no new interval if everything was cached", %{intv: intv} do
    Conn.hset("#{@prefix}.HOUR.2018-05-12T00:00:00Z", 123, 888)
    Conn.hset("#{@prefix}.HOUR.2018-05-12T01:00:00Z", 123, 999)
    {cached, new_intv} = get_increments(intv, "2018-05-12T01:14:59")
    assert length(cached) == 2
    assert Enum.at(cached, 0).count == 888
    assert Enum.at(cached, 1).count == 999
    assert_time Enum.at(cached, 0).time, "2018-05-12T00:00:00Z"
    assert_time Enum.at(cached, 1).time, "2018-05-12T01:00:00Z"
    assert new_intv == nil
  end

  defp cache_boundary(now) do
    Increments.cache_boundary get_dtim(now)
  end

  defp get_increments(intv, now) do
    Increments.get_increments @prefix, 123, intv, get_dtim(now)
  end
end
