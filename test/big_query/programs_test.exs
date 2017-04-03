defmodule Porter.BigQueryProgramsTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Programs

  @tag :external
  test "lists programs" do
    result = list(Timex.to_datetime(~D[2017-04-01]))
    assert is_list result
    assert length(result) > 10
    assert hd(result).program
    assert hd(result).impressions_past1 > 1
    assert hd(result).impressions_past12 > hd(result).impressions_past1
    assert hd(result).impressions_past24 > hd(result).impressions_past12
    assert hd(result).impressions_past48 > hd(result).impressions_past24
  end

  @tag :external
  test "shows program" do
    result = show("99pi", Timex.to_datetime(~D[2017-04-01]))
    assert is_map result
    assert result.program == "99pi"
    assert result.downloads_past1 >= 0
    assert result.downloads_past12 >= result.downloads_past1
    assert result.downloads_past24 >= result.downloads_past12
    assert result.downloads_past48 >= result.downloads_past24
    assert result.impressions_past1 > 1
    assert result.impressions_past12 > result.impressions_past1
    assert result.impressions_past24 > result.impressions_past12
    assert result.impressions_past48 > result.impressions_past24
  end
end
