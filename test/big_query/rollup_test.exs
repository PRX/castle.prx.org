defmodule Castle.BigQueryRollupTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup

  test "gets nothing for future days" do
    meta = for_day get_dtim("2030-01-01"), fn(_) -> ["nothing"] end
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets partial for today", "2017-05-01T15:14:13Z", [] do
    meta = for_day Timex.now, fn(_) -> %{meta: "data"} end
    assert_time Timex.to_date(meta.day), "2017-05-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 14
  end

  test_with_bq "gets complete for the past", "2017-05-01T15:14:13Z", [] do
    meta = for_day get_dtim("2017-04-29"), fn(_) -> %{meta: "data"} end
    assert_time Timex.to_date(meta.day), "2017-04-29T00:00:00Z"
    assert meta.complete == true
  end

  test "does not indicate a day is complete until 15 minutes after" do
    day = get_dtim("2018-05-23")
    assert completion_state(day, get_dtim("2018-05-01T22:00:00Z")) == :none
    assert completion_state(day, get_dtim("2018-05-22T23:59:59Z")) == :none
    assert completion_state(day, get_dtim("2018-05-23T00:00:00Z")) == :partial
    assert completion_state(day, get_dtim("2018-05-23T00:01:00Z")) == :partial
    assert completion_state(day, get_dtim("2018-05-24T00:00:00Z")) == :partial
    assert completion_state(day, get_dtim("2018-05-24T00:14:59Z")) == :partial
    assert completion_state(day, get_dtim("2018-05-24T00:15:00Z")) == :complete
    assert completion_state(day, get_dtim("2018-07-19T04:15:00Z")) == :complete
  end

  test "knows how many hours are complete, given a time" do
    assert hours_complete(get_dtim("2018-05-23T00:15:00Z")) == 0
    assert hours_complete(get_dtim("2018-05-23T01:14:59Z")) == 0
    assert hours_complete(get_dtim("2018-05-23T01:15:00Z")) == 1
    assert hours_complete(get_dtim("2018-05-23T11:14:59Z")) == 10
    assert hours_complete(get_dtim("2018-05-23T11:15:00Z")) == 11
    assert hours_complete(get_dtim("2018-05-23T23:59:59Z")) == 23
    assert hours_complete(get_dtim("2018-05-24T00:00:00Z")) == 23
    assert hours_complete(get_dtim("2018-05-24T00:14:59Z")) == 23
    assert hours_complete(get_dtim("2018-05-24T00:15:00Z")) == 0
  end
end
