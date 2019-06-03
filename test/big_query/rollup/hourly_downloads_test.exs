defmodule Castle.BigQueryRollupHourlyDownloadsTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.HourlyDownloads

  test_with_bq "gets empty hourly downloads in the past", [] do
    meta = query get_dtim("2016-01-01T05:04:00Z"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty hourly downloads in the future" do
    meta = query get_dtim("2030-01-01"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a partial day of downloads", "2017-05-01T05:14:37Z", [
    %{podcast_id: 1, episode_id: "a", hour: 2, count: 123},
    %{podcast_id: 2, episode_id: "b", hour: 6, count: 456},
    %{podcast_id: 1, episode_id: "a", hour: 1, count: 789},
  ] do
    meta = query get_dtim("2017-05-01"), fn(results) ->
      assert length(results) == 3
      assert hd(results).podcast_id == 1
      assert hd(results).episode_id == "a"
      assert hd(results).count == 123
      assert_time Enum.at(results, 0).dtim, "2017-05-01T02:00:00Z"
      assert_time Enum.at(results, 1).dtim, "2017-05-01T06:00:00Z"
      assert_time Enum.at(results, 2).dtim, "2017-05-01T01:00:00Z"
    end
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 4
  end

  @tag :external
  test "actually gets data" do
    meta = query get_dtim("2017-05-01"), fn(results) ->
      assert length(results) == 24248
      assert format_dtim(hd(results).dtim) =~ ~r/2017-05-01T[0-2][0-9]:00:00/
    end
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == true
  end
end
