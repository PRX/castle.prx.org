defmodule Castle.RedisConnTest do
  use Castle.RedisCase, async: true

  @moduletag :redis

  import Castle.Redis.Conn

  setup do
    redis_clear("conn_test_*")
    []
  end

  test "gets and sets objects" do
    assert get("conn_test_key1") == nil
    assert set("conn_test_key1", %{hello: "world"}) == %{hello: "world"}
    assert get("conn_test_key1") == %{hello: "world"}
  end

  test "gets and sets multiple keys at a time" do
    keys = ~w(conn_test_key1 conn_test_key2 foobar)
    assert get(keys) == [nil, nil, nil]
    set(%{
      conn_test_key1: "someval",
      conn_test_key2: %{other: "val"},
    })
    assert get(keys) == ["someval", %{other: "val"}, nil]
  end

  test "deletes objects" do
    assert set("conn_test_key1", 1234) == 1234
    assert get("conn_test_key1") == 1234
    assert del("conn_test_key1") == true
    assert del("conn_test_key1") == false
    assert get("conn_test_key1") == nil
  end
end
