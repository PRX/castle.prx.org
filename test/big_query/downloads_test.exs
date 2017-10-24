defmodule Castle.BigQueryDownloadsTest do
  use Castle.BigQueryCase, async: true

  @moduletag :external

  import BigQuery.Downloads

  test "lists downloads for a podcast" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", BigQuery.TimestampRollups.QuarterHourly)
    {result, _meta} = for_podcast(57, intv)

    assert is_list result
    assert length(result) == 26
    assert hd(result).time
    assert_time result, 0, "2017-06-27T21:45:00Z"
    assert hd(result).count > 0
  end

  test "lists downloads for an episode" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", BigQuery.TimestampRollups.Hourly)
    {result, _meta} = for_episode("7acf74b8-7b0a-4e9e-90be-f69052064b77", intv)

    assert is_list result
    assert length(result) == 8
    assert hd(result).time
    assert_time result, 0, "2017-06-27T21:00:00Z"
    assert hd(result).count > 0
  end
end
