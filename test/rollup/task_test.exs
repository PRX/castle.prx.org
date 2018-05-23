defmodule Castle.RollupTaskTest do
  use Castle.DataCase, async: true
  use Castle.RedisCase
  use Castle.TimeHelpers

  defmodule DefaultsTask do
    use Castle.Rollup.Task
    def run(_args), do: nil
  end

  defmodule FakeTask do
    use Castle.Rollup.Task
    @table "foo"
    @lock_ttl 100
    @default_count 1
    def run(_args), do: nil
    def done(log), do: set_complete(log)
    def undone(log), do: set_incomplete(log)
  end

  setup do
    redis_clear("lock.rollup.*")
    []
  end

  test "has default attributes" do
    assert DefaultsTask.get_attribute(:table) == "does_not_exist"
    assert DefaultsTask.get_attribute(:lock) == "lock.rollup"
    assert DefaultsTask.get_attribute(:lock_ttl) == 50
    assert DefaultsTask.get_attribute(:lock_success_ttl) == 200
    assert DefaultsTask.get_attribute(:default_count) == 5
  end

  test "has override values" do
    assert FakeTask.get_attribute(:table) == "foo"
    assert FakeTask.get_attribute(:lock_ttl) == 100
    assert FakeTask.get_attribute(:default_count) == 1
  end

  test "locks the worker function" do
    assert ["val1"] == FakeTask.do_rollup [date: "20180101", lock: true], fn(_) -> "val1" end
    assert [:locked] == FakeTask.do_rollup [date: "20180101", lock: true], fn(_) -> "val2" end
  end

  test "iterates through dates" do
    today = Timex.now |> Timex.to_date
    yesterday = today |> Timex.shift(days: -1)
    roll1 = FakeTask.do_rollup [], fn(log) ->
      FakeTask.done(log)
      log.date
    end
    roll2 = FakeTask.do_rollup [], fn(log) ->
      FakeTask.undone(log)
      log.date
    end
    roll3 = FakeTask.do_rollup [], fn(log) -> log.date end
    assert [today] == roll1
    assert [yesterday] == roll2
    assert [yesterday] == roll3
  end
end
