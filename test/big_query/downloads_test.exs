defmodule Porter.BigQueryDownloadsTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Downloads

  @tag :external
  test "lists downloads for a podcast" do
    {:ok, start, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-04-10T04:15:00Z")
    {result, _meta} = for_podcast(45, start, finish, 900)

    assert is_list result
    assert length(result) == 26
    assert hd(result).time
    assert Timex.to_unix(hd(result).time) == 1491774300
    assert hd(result).count > 0
  end

  @tag :external
  test "lists downloads for an episode" do
    {:ok, start, _} = DateTime.from_iso8601("2017-04-09T21:45:00Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-04-10T04:15:00Z")
    {result, _meta} = for_episode("66e048bf-5bb5-4818-be56-729a91e8f777", start, finish, 3600)

    assert is_list result
    assert length(result) == 8
    assert hd(result).time
    assert Timex.to_unix(hd(result).time) == 1491771600
    assert hd(result).count > 0
  end
end
