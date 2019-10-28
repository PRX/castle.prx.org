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

  defmodule MonthlyTask do
    use Castle.Rollup.Task
    @interval "month"
    def run(_args), do: nil
  end

  defmodule SingletonTask do
    use Castle.Rollup.Task
    @interval "singleton"
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

  test "iterates through days" do
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

  test "iterates through months" do
    this_month = Timex.now |> Timex.beginning_of_month |> Timex.to_date
    last_month = Timex.shift(this_month, months: -1)
    prev_month = Timex.shift(this_month, months: -2)
    rolls = MonthlyTask.do_rollup [count: 3], fn(log) -> log.date end
    assert length(rolls) == 3
    assert Enum.at(rolls, 0) == this_month
    assert Enum.at(rolls, 1) == last_month
    assert Enum.at(rolls, 2) == prev_month
  end

  test "handles a singleton lookup" do
    today = Timex.now |> Timex.to_date
    roll1 = SingletonTask.do_rollup [], fn(log) ->
      SingletonTask.done(log)
      log.date
    end
    roll2 = SingletonTask.do_rollup [], fn(log) ->
      SingletonTask.done(log)
      log.date
    end
    assert length(roll1) == 1
    assert Enum.at(roll1, 0) == today

    assert length(roll2) == 0
  end
end
