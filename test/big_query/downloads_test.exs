defmodule Castle.BigQueryDownloadsTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Downloads

  @tag :external
  test "lists downloads for a podcast" do
    {:ok, start, _} = DateTime.from_iso8601("2017-06-27T21:45:00Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-06-28T04:15:00Z")
    {result, _meta} = for_podcast(57, start, finish, 900)

    assert is_list result
    assert length(result) == 26
    assert hd(result).time
    assert Timex.to_unix(hd(result).time) == 1498599900
    assert hd(result).count > 0
  end

  @tag :external
  test "lists downloads for an episode" do
    {:ok, start, _} = DateTime.from_iso8601("2017-06-27T21:45:00Z")
    {:ok, finish, _} = DateTime.from_iso8601("2017-06-28T04:15:00Z")
    {result, _meta} = for_episode("7acf74b8-7b0a-4e9e-90be-f69052064b77", start, finish, 3600)

    assert is_list result
    assert length(result) == 8
    assert hd(result).time
    assert Timex.to_unix(hd(result).time) == 1498597200
    assert hd(result).count > 0
  end
end
