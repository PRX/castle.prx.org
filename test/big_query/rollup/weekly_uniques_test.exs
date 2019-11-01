defmodule Castle.BigQueryRollupWeeklyUniquesTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.WeeklyUniques

  test_with_bq "gets empty weekly uniques in the past", [] do
    meta = query get_dtim("2016-01-03T05:04:00Z"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2016-01-03T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty weekly uniques in the future" do
    meta = query get_dtim("2030-01-06"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2030-01-06T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a week of uniques count", "2017-05-07T05:14:37Z", [
    %{podcast_id: 1, week: ~D[2019-05-05], count: 123},
  ] do
    meta = query get_dtim("2019-05-05"), fn(results) ->
      assert length(results) == 1
      assert hd(results).podcast_id == 1
      assert hd(results).week == ~D[2019-05-05]
      assert hd(results).count == 123
    end
    assert_time meta.day, "2019-05-05T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  @tag :external
  test "actually gets data" do
    meta = query get_dtim("2019-05-06"), fn(results) ->
      assert length(results) == 113
      assert hd(results).week == ~D[2019-05-05]
      assert hd(results).count == 41162
    end
    assert_time meta.day, "2019-05-06T00:00:00Z"
    assert meta.complete == true
  end
end
