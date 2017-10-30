defmodule Castle.RedisIntervalCacheKeysTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  alias Castle.Redis.Interval.Keys, as: Keys

  test "returns keys for a range" do
    times = [
      get_dtim("2017-03-22T01:15:00Z"),
      get_dtim("2017-03-22T01:30:00Z"),
      get_dtim("2017-03-22T01:45:00Z"),
      get_dtim("2017-03-22T02:00:00Z"),
      get_dtim("2017-03-22T02:15:00Z")
    ]
    assert Keys.keys("foo.bar", times) == [
      "foo.bar.2017-03-22T01:15:00Z",
      "foo.bar.2017-03-22T01:30:00Z",
      "foo.bar.2017-03-22T01:45:00Z",
      "foo.bar.2017-03-22T02:00:00Z",
      "foo.bar.2017-03-22T02:15:00Z"
    ]
  end

  test "returns keys for empty range" do
    assert Keys.keys("foo.bar", []) == []
  end

  test "returns a single key" do
    assert Keys.key("foo.bar", get_dtim("2017-03-22T01:45:00Z")) == "foo.bar.2017-03-22T01:45:00Z"
  end
end
