defmodule Castle.RollupQueryDownloadsTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.Downloads

  @id 1234
  @guid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

  setup do
    Castle.HourlyDownload.upsert %{podcast_id: @id, episode_id: @guid,
      dtim: get_dtim("2018-04-24T13:00:00"), count: 123}
    Castle.HourlyDownload.upsert %{podcast_id: @id, episode_id: @guid,
      dtim: get_dtim("2018-04-24T14:00:00"), count: 456}
    Castle.HourlyDownload.upsert %{podcast_id: @id, episode_id: @guid,
      dtim: get_dtim("2018-04-25T01:00:00"), count: 789}
    []
  end

  test "gets hourly podcast downloads" do
    results = podcast(@id, get_dtim("2018-04-24T11:00:00"), get_dtim("2018-04-24T14:00:00"), "hour")
    assert length(results) == 1
    assert hd(results).count == 123
    assert_time hd(results).time, "2018-04-24T13:00:00Z"
  end

  test "gets daily podcast downloads" do
    intv = %{
      from: get_dtim("2018-04-22T00:00:00"),
      to: get_dtim("2018-04-25T00:00:00"),
      bucket: Castle.Bucket.Daily
    }
    results = podcast(@id, intv)
    assert length(results) == 1
    assert hd(results).count == 579
    assert_time hd(results).time, "2018-04-24T00:00:00Z"
  end

  test "gets weekly podcast downloads" do
    results = podcast(@id, get_dtim("2018-04-22T00:00:00"), get_dtim("2018-04-29T00:00:00"), "week")
    assert length(results) == 1
    assert hd(results).count == 1368
    assert_time hd(results).time, "2018-04-22T00:00:00Z"
  end

  test "gets monthly podcast downloads" do
    results = podcast(@id, get_dtim("2018-04-22T00:00:00"), get_dtim("2018-04-25T00:00:00"), "month")
    assert length(results) == 1
    assert hd(results).count == 579
    assert_time hd(results).time, "2018-04-01T00:00:00Z"
  end

  test "gets hourly episode downloads" do
    results = episode(@guid, get_dtim("2018-04-24T11:00:00"), get_dtim("2018-04-24T15:00:00"), "hour")
    assert length(results) == 2
    assert hd(results).count == 123
    assert_time hd(results).time, "2018-04-24T13:00:00Z"
    assert List.last(results).count == 456
    assert_time List.last(results).time, "2018-04-24T14:00:00Z"
  end

  test "gets daily episode downloads" do
    results = episode(@guid, get_dtim("2018-04-22T00:00:00"), get_dtim("2018-04-25T01:59:59"), "day")
    assert length(results) == 2
    assert hd(results).count == 579
    assert_time hd(results).time, "2018-04-24T00:00:00Z"
    assert List.last(results).count == 789
    assert_time List.last(results).time, "2018-04-25T00:00:00Z"
  end

  test "gets weekly episode downloads" do
    intv = %{
      from: get_dtim("2018-04-24T14:00:00"),
      to: get_dtim("2018-04-25T02:00:00"),
      bucket: Castle.Bucket.Weekly
    }
    results = episode(@guid, intv)
    assert length(results) == 1
    assert hd(results).count == 1245
    assert_time hd(results).time, "2018-04-22T00:00:00Z"
  end

  test "gets monthly episode downloads" do
    results = episode(@guid, get_dtim("2018-04-01T00:00:00"), get_dtim("2018-04-26T00:00:00"), "month")
    assert length(results) == 1
    assert hd(results).count == 1368
    assert_time hd(results).time, "2018-04-01T00:00:00Z"
  end
end
