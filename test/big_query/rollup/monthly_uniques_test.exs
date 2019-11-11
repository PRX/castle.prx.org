defmodule Castle.BigQueryRollupMonthlyUniquesTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.MonthlyUniques

  test_with_bq "gets empty monthly uniques in the past", [] do
    meta = query get_dtim("2016-01-01T05:04:00Z"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2016-01-01T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty monthly uniques in the future" do
    meta = query get_dtim("2030-01-01"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2030-01-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a month of uniques count", "2017-05-01T05:14:37Z", [
    %{podcast_id: 1, month: ~D[2017-05-01], count: 123},
  ] do
    meta = query get_dtim("2017-05-01"), fn(results) ->
      assert length(results) == 1
      assert hd(results).podcast_id == 1
      assert hd(results).month == ~D[2017-05-01]
      assert hd(results).count == 123
    end
    assert_time meta.day, "2017-05-01T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 4
  end

  @tag :external
  test "actually gets data" do
    meta = query get_dtim("2019-05-02"), fn(results) ->
      assert length(results) == 118
      assert hd(results).month == ~D[2019-05-01]
      assert hd(results).count == 199662
    end
    assert_time meta.day, "2019-05-02T00:00:00Z"
    assert meta.complete == true
  end
end
