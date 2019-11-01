defmodule Castle.BigQueryRollupLast28UniquesTest do
  use Castle.BigQueryCase

  import BigQuery.Rollup.Last28Uniques

  test_with_bq "gets empty last 28 uniques in the past", [] do
    meta = query get_dtim("2016-01-03T05:04:00Z"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2016-01-03T00:00:00Z"
    assert meta.complete == true
  end

  test "gets empty last 28 uniques in the future" do
    meta = query get_dtim("2030-01-06"), fn(results) ->
      assert length(results) == 0
    end
    assert_time meta.day, "2030-01-06T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  test_with_bq "gets a 28 day window of uniques count", "2017-05-07T05:14:37Z", [
    %{podcast_id: 1, last_28: ~D[2019-05-07], count: 123},
    %{podcast_id: 2, last_28: ~D[2019-05-07], count: 234},
    %{podcast_id: 2, last_28: ~D[2019-05-07], count: 345},
  ] do
    meta = query get_dtim("2019-05-07"), fn(results) ->
      assert length(results) == 3
      assert hd(results).podcast_id == 1
      assert hd(results).week == ~D[2019-05-07]
      assert hd(results).count == 123
    end
    assert_time meta.day, "2019-05-07T00:00:00Z"
    assert meta.complete == false
    assert meta.hours_complete == 0
  end

  @tag :external
  test "actually gets data" do
    meta = query get_dtim("2019-05-07T05:14:37Z"), fn(results) ->
      assert length(results) == 115
      assert hd(results).last_28 == ~D[2019-05-07]
      assert hd(results).count == 240769
    end
    assert_time meta.day, "2019-05-07T00:00:00Z"
    assert meta.complete == true
  end
end
