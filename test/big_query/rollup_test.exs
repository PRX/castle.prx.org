defmodule Castle.BigQueryRollupTest do
  use Castle.BigQueryCase, async: false
  use Castle.TimeHelpers

  import BigQuery.Rollup
  import Mock

  @tag :external
  test "gets empty hourly downloads in the past" do
    {results, meta} = hourly_downloads(get_dtim("2016-01-01T05:04:00Z"))
    assert length(results) == 0
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty hourly downloads in the future" do
    {results, meta} = hourly_downloads(get_dtim("2030-01-01"))
    assert length(results) == 0
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  @tag :external
  test "gets a partial day of downloads" do
    with_mock Timex, [:passthrough], [now: fn() -> get_dtim("2017-05-01T05:14:37Z") end] do
      {results, meta} = hourly_downloads(get_dtim("2017-05-01"))
      assert length(results) == 24248 # known
      assert_time meta.day, "2017-05-01T00:00:00Z"
      assert meta.complete == false
      assert meta.hours_complete == 4

      assert format_dtim(hd(results).hour) =~ ~r/2017-05-01T[0-2][0-9]:00:00/
      assert is_binary hd(results).episode_guid
      assert is_number hd(results).podcast_id
      assert hd(results).count > 0
    end
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
