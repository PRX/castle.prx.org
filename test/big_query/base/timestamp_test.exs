defmodule Castle.BigQueryBaseTimestampTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Base.Timestamp

  test "adds a where condition" do
    sql = timestamp_sql("the_table", "foo = @bar")
    assert sql =~ ~r/FROM the_table/
    assert sql =~ ~r/AND foo = @bar/
  end

  test "sets params" do
    {:ok, start, _} = DateTime.from_iso8601("2017-03-22T21:54:52Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-03-28T04:12:00Z")
    params = timestamp_params(start, finish, 900)

    assert Timex.to_unix(params.from_dtim) == 1490219692
    assert Timex.to_unix(params.to_dtim) == 1490674320
    assert Timex.to_unix(params.pstart) == 1490140800
    assert Timex.to_unix(params.pend) == 1490745599
    assert params.interval_s == 900
  end
end
