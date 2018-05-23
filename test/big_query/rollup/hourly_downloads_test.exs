defmodule Castle.BigQueryRollupHourlyDownloadsTest do
  use Castle.BigQueryCase, async: false
  use Castle.TimeHelpers

  import BigQuery.Rollup.HourlyDownloads
  import Mock

  @tag :external
  test "gets empty hourly downloads in the past" do
    {results, meta} = query(get_dtim("2016-01-01T05:04:00Z"))
    assert length(results) == 0
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty hourly downloads in the future" do
    {results, meta} = query(get_dtim("2030-01-01"))
    assert length(results) == 0
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  @tag :external
  test "gets a partial day of downloads" do
    with_mock Timex, [:passthrough], [now: fn() -> get_dtim("2017-05-01T05:14:37Z") end] do
      {results, meta} = query(get_dtim("2017-05-01"))
      assert length(results) == 24248 # known
      assert_time meta.day, "2017-05-01T00:00:00Z"
      assert meta.complete == false
      assert meta.hours_complete == 4

      assert format_dtim(hd(results).dtim) =~ ~r/2017-05-01T[0-2][0-9]:00:00/
      assert is_binary hd(results).episode_id
      assert is_number hd(results).podcast_id
      assert hd(results).count > 0
    end
  end
end
