defmodule Castle.BigQueryDownloadsTest do
  use Castle.BigQueryCase, async: true
  use Castle.TimeHelpers

  @moduletag :external

  import BigQuery.Downloads

  test "lists downloads for all podcasts" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", BigQuery.TimestampRollups.QuarterHourly)
    {result, _meta} = for_podcasts(intv)

    assert is_list result
    assert length(result) == 26

    {time, counts} = Enum.at(result, 0)
    assert_time time, "2017-06-27T21:45:00Z"
    assert length(Map.keys(counts)) > 10
    assert Map.has_key?(counts, 57)
    assert Map.get(counts, 57) == 1710
  end

  test "groups downloads for a podcast" do
    intv = interval("2017-07-10T21:45:00Z", "2017-07-11T04:15:00Z", BigQuery.TimestampRollups.QuarterHourly)
    group = Castle.Plugs.Group.get("city", 3)
    {result, _meta} = group_podcast(57, intv, group)

    assert is_list result
    assert length(result) == 26 * 4

    assert_time result, 0, "2017-07-10T21:45:00Z"
    assert_time result, 1, "2017-07-10T21:45:00Z"
    assert_time result, 2, "2017-07-10T21:45:00Z"
    assert_time result, 3, "2017-07-10T21:45:00Z"
    assert_time result, 4, "2017-07-10T22:00:00Z"

    assert Enum.at(result, 0).display == nil
    assert Enum.at(result, 1).display != nil
    assert Enum.at(result, 2).display != nil
    assert Enum.at(result, 3).display != nil
    assert Enum.at(result, 4).display == nil
    assert Enum.at(result, 5).display == Enum.at(result, 1).display
    assert Enum.at(result, 6).display == Enum.at(result, 2).display
    assert Enum.at(result, 7).display == Enum.at(result, 3).display
  end

  test "lists downloads for all episodes" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", BigQuery.TimestampRollups.QuarterHourly)
    {result, _meta} = for_episodes(intv)

    assert is_list result
    assert length(result) == 26

    {time1, counts} = Enum.at(result, 0)
    {time2, _counts} = Enum.at(result, 1)
    assert_time time1, "2017-06-27T21:45:00Z"
    assert_time time2, "2017-06-27T22:00:00Z"
    assert length(Map.keys(counts)) > 10
    assert Map.has_key?(counts, "e4f5a88b-b383-493a-b7f3-8b8ea52cbf35")
    assert Map.get(counts, "e4f5a88b-b383-493a-b7f3-8b8ea52cbf35") == 234
  end

  test "groups downloads for an episode" do
    intv = interval("2017-07-10T21:45:00Z", "2017-07-11T04:15:00Z", BigQuery.TimestampRollups.QuarterHourly)
    group = Castle.Plugs.Group.get("country", 2)
    {result, _meta} = group_episode("7acf74b8-7b0a-4e9e-90be-f69052064b77", intv, group)

    assert is_list result
    assert length(result) == 26 * 3

    assert_time result, 0, "2017-07-10T21:45:00Z"
    assert_time result, 1, "2017-07-10T21:45:00Z"
    assert_time result, 2, "2017-07-10T21:45:00Z"
    assert_time result, 3, "2017-07-10T22:00:00Z"

    assert Enum.at(result, 0).display == nil
    assert Enum.at(result, 1).display != nil
    assert Enum.at(result, 2).display != nil
    assert Enum.at(result, 3).display == nil
    assert Enum.at(result, 4).display == Enum.at(result, 1).display
    assert Enum.at(result, 5).display == Enum.at(result, 2).display
  end
end
