defmodule Castle.RedisHashCacheTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  import Castle.Redis.HashCache
  alias Castle.Redis.Conn, as: Conn

  @key "hash.cache.test"

  setup do
    redis_clear(@key)
    today = Timex.beginning_of_day(Timex.now)
    {:ok, today_str} = Timex.format(today, "{ISO:Extended:Z}")
    [today: today_str]
  end

  test "fetches from the beginning of time", %{today: today} do
    {_data, %{job: {from, to}}} = hash_cache @key, fn(from, to) ->
      case {from, to} do
        {nil, nil} -> {%{skip: 1}, %{}}
        {nil, _to} -> {%{fullfetch: 1}, %{}}
        {_from, _to} -> {%{partialfetch: 1}, %{}}
      end
    end
    assert from == nil
    assert_time to, today
    assert Conn.hget(@key, "_last_updated") == today
    assert Conn.hget(@key, "skip") == nil
    assert Conn.hget(@key, "fullfetch") == 1
    assert Conn.hget(@key, "partialfetch") == nil
  end

  test "fetches from a specific date", %{today: today} do
    Conn.hsetall(@key, %{_last_updated: "2018-02-01T00:00:00Z", partialfetch: 2})
    {_data, %{job: {from, to}}} = hash_cache @key, fn(from, to) ->
      case {from, to} do
        {nil, nil} -> {%{skip: 1}, %{}}
        {nil, _to} -> {%{fullfetch: 1}, %{}}
        {_from, _to} -> {%{partialfetch: 1}, %{}}
      end
    end
    assert_time from, "2018-02-01T00:00:00Z"
    assert_time to, today
    assert Conn.hget(@key, "_last_updated") == today
    assert Conn.hget(@key, "skip") == nil
    assert Conn.hget(@key, "fullfetch") == nil
    assert Conn.hget(@key, "partialfetch") == 3
  end

  test "skips fetching entirely", %{today: today} do
    Conn.hsetall(@key, %{_last_updated: today})
    {_data, meta} = hash_cache @key, fn(from, to) ->
      case {from, to} do
        {nil, nil} -> {%{skip: 1}, %{}}
        {nil, _to} -> {%{fullfetch: 1}, %{}}
        {_from, _to} -> {%{partialfetch: 1}, %{}}
      end
    end
    assert Map.has_key?(meta, :job) == false
    assert meta.cached == true
    assert Conn.hget(@key, "_last_updated") == today
    assert Conn.hget(@key, "skip") == nil
    assert Conn.hget(@key, "fullfetch") == nil
    assert Conn.hget(@key, "partialfetch") == nil
  end

  test "retrieves set values", %{today: today} do
    Conn.hsetall(@key, %{
      "_last_updated" => today,
      "foo" => 99,
      "bar" => 101,
    })
    assert hash_fetch(@key, "foo") == 99
    assert hash_fetch(@key, "bar") == 101
    assert hash_fetch(@key, "whatev") == nil
  end

  test "supplements fetched values with current data", %{today: today} do
    Conn.hsetall(@key, %{
      "_last_updated" => today,
      "foo" => 99,
      "bar" => 101,
    })
    assert run_fetch(@key, "foo", 3, today) == 102
    assert run_fetch(@key, "bar", 3, today) == 104
    assert run_fetch(@key, "whatev", 3, today) == nil
    assert run_fetch("#{@key}.dne", "foo", 3, today) == nil
  end

  defp run_fetch(key, field, num, expected_time) do
    hash_fetch(key, field, fn(from) ->
      assert_time from, expected_time
      num
    end)
  end
end
