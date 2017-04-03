defmodule Porter.BigQueryProgramsTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Programs

  @tag :external
  test "lists programs" do
    result = list(Timex.to_datetime(~D[2017-04-01]))
    assert is_list result
    assert length(result) > 10
    assert hd(result).program
    assert hd(result).past1 > 1
    assert hd(result).past12 > hd(result).past1
    assert hd(result).past24 > hd(result).past12
    assert hd(result).past48 > hd(result).past24
  end

  @tag :external
  test "shows program" do
    result = show("99pi", Timex.to_datetime(~D[2017-04-01]))
    assert is_map result
    assert result.program == "99pi"
    assert result.past1 > 1
    assert result.past12 > result.past1
    assert result.past24 > result.past12
    assert result.past48 > result.past24
  end
end
