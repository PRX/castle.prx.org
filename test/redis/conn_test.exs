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
      conn_test_key2: %{other: "val"}
    })

    assert get(keys) == ["someval", %{other: "val"}, nil]
  end

  test "gets and sets hashes" do
    assert hget(["conn_test_key1"], "f1") == [[false, nil]]
    hsetall("conn_test_key1", %{f1: 999, f3: 777})
    assert hget(["conn_test_key1"], "f1") == [[true, 999]]
    assert hget(["conn_test_key1"], "f2") == [[true, nil]]
    assert hget(["conn_test_key1", "conn_test_key2"], "f1") == [[true, 999], [false, nil]]
    assert hget(["conn_test_key1", "conn_test_key2"], "f2") == [[true, nil], [false, nil]]
    hsetall("conn_test_key1", %{f3: 777})
    assert hget(["conn_test_key1"], "f1") == [[true, nil]]
  end

  test "gets entire hashes" do
    hsetall("conn_test_key1", %{f1: 999, f3: 777})
    assert hgetall("conn_test_key1") == %{"f1" => 999, "f3" => 777}
    assert hgetall("conn_test_key2") == %{}
  end

  test "returns the ttl for keys" do
    assert ttl("conn_test_key1") == -2
    set("conn_test_key1", "val1")
    assert ttl("conn_test_key1") == -1
    set("conn_test_key1", 99, "val1")
    assert ttl("conn_test_key1") >= 98
  end

  test "sets empty hashes with ttl" do
    assert hget(["conn_test_key1"], "f1") == [[false, nil]]
    hsetall("conn_test_key1", %{})
    assert hget(["conn_test_key1"], "f1") == [[true, nil]]
    assert command(["TTL", "conn_test_key1"]) == -1
    hsetall("conn_test_key1", %{}, 10)
    assert command(["TTL", "conn_test_key1"]) == 10
  end

  test "sets when the key does not exist" do
    assert setnx("conn_test_key1", 99, "val1") == true
    assert setnx("conn_test_key1", 11, "val2") == false
    assert ttl("conn_test_key1") >= 98
  end

  test "deletes objects" do
    assert set("conn_test_key1", 1234) == 1234
    assert get("conn_test_key1") == 1234
    assert del("conn_test_key1") == true
    assert del("conn_test_key1") == false
    assert get("conn_test_key1") == nil
  end
end
