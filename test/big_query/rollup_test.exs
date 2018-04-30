defmodule Castle.BigQueryRollupTest do
  use Castle.BigQueryCase, async: true
  use Castle.TimeHelpers

  import BigQuery.Rollup

  @tag :external
  test "gets empty daily downloads in the past" do
    {results, meta} = daily_downloads(get_dtim("2016-01-01T05:04:00Z"))
    assert length(results) == 0
    assert meta.max_hour == 23
    assert_time meta.day, "2016-01-01T00:00:00Z"
  end

  test "gets empty daily downloads in the future" do
    assert :no_data = daily_downloads(get_dtim("2030-01-01"))
    assert :no_data = daily_downloads(get_dtim("2018-05-23"), get_dtim("2018-05-23T01:04:00Z"))
  end

  @tag :external
  test "gets a partial day of downloads" do
    {results, meta} = daily_downloads(get_dtim("2017-05-01"), get_dtim("2017-05-01T01:34:37Z"))
    assert length(results) == 702 # known
    assert meta.max_hour == 0
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert_time hd(results).hour, "2017-05-01T00:00:00Z"
    assert is_binary hd(results).episode_guid
    assert is_number hd(results).podcast_id
    assert hd(results).count > 0
  end

  test "buffers the max hour based on the current time" do
    day = get_dtim("2018-05-23")
    assert max_hour(day, get_dtim("2018-05-22T22:00:00Z")) == :no_data
    assert max_hour(day, get_dtim("2018-05-23T00:10:00Z")) == :no_data
    assert max_hour(day, get_dtim("2018-05-23T01:04:00Z")) == :no_data
    assert max_hour(day, get_dtim("2018-05-23T01:05:00Z")).hour == 1
    assert max_hour(day, get_dtim("2018-05-23T19:11:00Z")).hour == 19
    assert max_hour(day, get_dtim("2018-05-24T00:04:59Z")).hour == 23
    assert max_hour(day, get_dtim("2018-05-24T00:05:00Z")) == :no_max
    assert max_hour(day, get_dtim("2018-05-24T04:15:00Z")) == :no_max
  end
end
