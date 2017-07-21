defmodule Castle.BigQueryImpressionsTest do
  use Castle.BigQueryCase, async: true

  @moduletag :external

  import BigQuery.Impressions

  test "lists impressions for a podcast" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", 900)
    {result, _meta} = for_podcast(57, intv)

    assert is_list result
    assert length(result) == 26
    assert hd(result).time
    assert Timex.to_unix(hd(result).time) == 1498599900
    assert hd(result).count > 0
  end

  test "groups impressions by city for a podcast" do
    intv = interval("2017-07-10T21:45:00Z", "2017-07-11T04:15:00Z", 900)
    group = Castle.Plugs.Group.get("city", 3)
    {result, _meta} = for_podcast(57, intv, group)
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

  test "lists impressions for an episode" do
    intv = interval("2017-06-27T21:45:00Z", "2017-06-28T04:15:00Z", 3600)
    {result, _meta} = for_episode("7acf74b8-7b0a-4e9e-90be-f69052064b77", intv)

    assert is_list result
    assert length(result) == 8
    assert hd(result).time
    assert_time result, 0, "2017-06-27T21:00:00Z"
    assert hd(result).count > 0
  end
end
