defmodule Castle.RollupTaskTest do
  use Castle.DataCase, async: true
  use Castle.RedisCase
  use Castle.TimeHelpers

  defmodule DefaultsTask do
    use Castle.Rollup.Task
    def run(_args), do: nil
    def log(_, _), do: nil
    defp query(_), do: {[], %{complete: true}}
    def upsert(_), do: nil
  end

  defmodule FakeTask do
    use Castle.Rollup.Task
    @table "foo"
    @lock_ttl 100
    @default_count 1
    def run(_args), do: nil
    def log(_, _), do: nil
    def query(_), do: {[], %{complete: true}}
    def upsert(_), do: nil
  end

  defmodule FakeIncompleteTask do
    use Castle.Rollup.Task
    @table "foo"
    @default_count 1
    def run(_args), do: nil
    def log(_, _), do: nil
    def query(_), do: {[], %{complete: false}}
    def upsert(_), do: nil
  end

  defmodule MonthlyTask do
    use Castle.Rollup.Task
    @interval "month"
    def run(_args), do: nil
    def log(_, _), do: nil
    def query(_), do: {[], %{complete: true}}
    def upsert(_), do: nil
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
    assert [~D[2018-01-01]] == FakeTask.rollup([date: "20180101", lock: true])
    assert [:locked] == FakeTask.rollup([date: "20180101", lock: true])
  end

  test "iterates through days" do
    today = Timex.now |> Timex.to_date
    yesterday = today |> Timex.shift(days: -1)
    roll1 = FakeTask.rollup()
    roll2 = FakeIncompleteTask.rollup()
    roll3 = FakeTask.rollup()
    assert [today] == roll1
    assert [yesterday] == roll2
    assert [yesterday] == roll3
  end

  test "iterates through months" do
    this_month = Timex.now |> Timex.beginning_of_month |> Timex.to_date
    last_month = Timex.shift(this_month, months: -1)
    prev_month = Timex.shift(this_month, months: -2)
    rolls = MonthlyTask.rollup(count: 3)
    assert length(rolls) == 3
    assert Enum.at(rolls, 0) == this_month
    assert Enum.at(rolls, 1) == last_month
    assert Enum.at(rolls, 2) == prev_month
  end
end
