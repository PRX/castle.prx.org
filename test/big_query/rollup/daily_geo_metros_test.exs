defmodule Castle.BigQueryRollupDailyGeoMetrosTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.DailyGeoMetros

  test_with_bq "gets empty geo metros in the past", [] do
    {results, meta} = query(get_dtim("2016-01-01T05:04:00Z"))
    assert length(results) == 0
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty geo metros in the future" do
    {results, meta} = query(get_dtim("2030-01-01"))
    assert length(results) == 0
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a partial day of geo metros", "2017-05-01T05:14:37Z", [
    %{podcast_id: 1, episode_id: "a", metro_code: 9999, count: 123},
    %{podcast_id: 2, episode_id: "b", metro_code: 8888, count: 456},
    %{podcast_id: 1, episode_id: "a", metro_code: 7777, count: 789},
  ] do
    {results, meta} = query(get_dtim("2017-05-01"))
    assert length(results) == 3
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 4
    assert hd(results).podcast_id == 1
    assert hd(results).episode_id == "a"
    assert hd(results).metro_code == 9999
    assert hd(results).count == 123
    assert hd(results).day == ~D[2017-05-01]
  end

  @tag :external
  test "actually gets data" do
    {results, meta} = query(get_dtim("2017-05-01"))
    assert length(results) == 48440
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == true
    assert hd(results).day == ~D[2017-05-01]
    assert hd(results).metro_code > 0
  end
end
