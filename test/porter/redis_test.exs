defmodule Porter.RedisTest do
  use Porter.RedisCase, async: true

  import Porter.Redis

  setup do
    del("some_cache_key")
    del("other_cache_key")
    []
  end

  @tag :redis
  test "gets and sets objects" do
    assert get("some_cache_key") == nil
    assert set("some_cache_key", %{hello: "world"}) == %{hello: "world"}
    assert get("some_cache_key") == %{hello: "world"}
  end

  @tag :redis
  test "gets and sets multiple keys at a time" do
    keys = ~w(some_cache_key other_cache_key foobar)
    assert get(keys) == [nil, nil, nil]
    set(%{
      some_cache_key: "someval",
      other_cache_key: %{other: "val"},
    })
    assert get(keys) == ["someval", %{other: "val"}, nil]
  end

  @tag :redis
  test "deletes objects" do
    assert set("some_cache_key", 1234) == 1234
    assert get("some_cache_key") == 1234
    assert del("some_cache_key") == true
    assert del("some_cache_key") == false
    assert get("some_cache_key") == nil
  end

  @tag :external
  test "caches function results" do
    val = cached("some_cache_key", 1, fn() -> "foo" end)
    assert val == "foo"
    val = cached("some_cache_key", 1, fn() -> "bar" end)
    assert val == "foo"
    :timer.sleep(1200);
    val = cached("some_cache_key", 1, fn() -> "last" end)
    assert val == "last"
  end
end
