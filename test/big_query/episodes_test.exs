defmodule Castle.BigQueryEpisodesTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Episodes

  @tag :external
  test "lists episodes" do
    {result, _meta} = list(Timex.to_datetime(~D[2017-06-27]))
    assert is_list result
    assert length(result) > 10
    assert hd(result).feeder_episode

    assert hd(result).downloads_past1 > 1
    assert hd(result).downloads_past12 >= hd(result).downloads_past1
    assert hd(result).downloads_past24 >= hd(result).downloads_past12
    assert hd(result).downloads_past48 >= hd(result).downloads_past24

    assert hd(result).impressions_past1 > 1
    assert hd(result).impressions_past12 >= hd(result).impressions_past1
    assert hd(result).impressions_past24 >= hd(result).impressions_past12
    assert hd(result).impressions_past48 >= hd(result).impressions_past24
  end

  @tag :external
  test "shows an episode" do
    {result, _meta} = show("7acf74b8-7b0a-4e9e-90be-f69052064b77", Timex.to_datetime(~D[2017-06-27]))
    assert is_map result
    assert result.feeder_episode == "7acf74b8-7b0a-4e9e-90be-f69052064b77"

    assert result.downloads_past1 > 1
    assert result.downloads_past12 >= result.downloads_past1
    assert result.downloads_past24 >= result.downloads_past12
    assert result.downloads_past48 >= result.downloads_past24

    assert result.impressions_past1 > 1
    assert result.impressions_past12 >= result.impressions_past1
    assert result.impressions_past24 >= result.impressions_past12
    assert result.impressions_past48 >= result.impressions_past24
  end
end
