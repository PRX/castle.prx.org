defmodule Castle.RollupTasksMonthlyTest do
  use Castle.DataCase, async: true
  use Castle.TimeHelpers

  test "identifies past months 1 day after they're over" do
    assert is_past_month?(~D[2018-04-01], "2018-03-29T00:00:00Z") == false
    assert is_past_month?(~D[2018-04-01], "2018-04-01T00:00:00Z") == false
    assert is_past_month?(~D[2018-04-01], "2018-04-30T23:59:59Z") == false
    assert is_past_month?(~D[2018-04-01], "2018-05-01T00:00:00Z") == false
    assert is_past_month?(~D[2018-04-01], "2018-05-01T23:59:59Z") == false
    assert is_past_month?(~D[2018-04-01], "2018-05-02T00:00:00Z") == true
    assert is_past_month?(~D[2018-04-01], "2018-05-02T00:00:01Z") == true
    assert is_past_month?(~D[2018-04-01], "2018-05-15T00:00:00Z") == true
  end

  def is_past_month?(date, dtim_str) do
    Mix.Tasks.Castle.Rollup.Monthly.is_past_month? date, get_dtim(dtim_str)
  end

end
