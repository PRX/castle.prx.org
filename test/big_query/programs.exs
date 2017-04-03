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
end
