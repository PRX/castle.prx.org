defmodule Castle.RedisLockTest do
  use Castle.RedisCase, async: true

  @moduletag :redis

  import Castle.Redis.Lock

  @lock "lock.redislock.test"

  setup do
    redis_clear("#{@lock}*")
    []
  end

  test "gets a lock for the duration of a block" do
    result = lock @lock, 500 do
      assert is_locked?(@lock) == true
      "value"
    end
    assert result == "value"
    assert is_locked?(@lock) == false
  end

  test "does not run if it cannot get the lock" do
    get_lock(@lock, 100)
    result = lock @lock, 500 do
      assert true == false
    end
    assert result == :locked
    assert is_locked?(@lock) == true
    assert Castle.Redis.Conn.ttl(@lock) <= 100
  end

  test "unlocks when an error is thrown" do
    assert_raise RuntimeError, "whatevs", fn ->
      lock @lock, 500, do: raise "whatevs"
    end
    assert is_locked?(@lock) == false
  end

  test "delays unlocking" do
    result = lock @lock, 500, 5 do
      assert is_locked?(@lock) == true
      assert Castle.Redis.Conn.ttl(@lock) <= 500
      assert Castle.Redis.Conn.ttl(@lock) >= 499
      "value"
    end
    assert result == "value"
    assert is_locked?(@lock) == true
    assert is_unlocking?(@lock) == true
    assert Castle.Redis.Conn.ttl(@lock) <= 5
  end

  test "does not delay unlocking  when an error is thrown" do
    assert_raise RuntimeError, "whatevs", fn ->
      lock @lock, 500, 5, do: raise "whatevs"
    end
    assert is_locked?(@lock) == false
  end

end
