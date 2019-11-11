defmodule Castle.RollupTasksWeeklyTest do
  use Castle.DataCase, async: true
  use Castle.TimeHelpers

  test "identifies elapsed weeks 1 day after they're over" do
    assert is_past_week?(~D[2019-10-30], "2019-03-29T00:00:00Z") == false
    assert is_past_week?(~D[2019-10-30], "2019-10-30T00:00:00Z") == false
    assert is_past_week?(~D[2019-10-30], "2019-11-06T23:59:59Z") == false
    assert is_past_week?(~D[2019-10-30], "2019-11-06T00:00:00Z") == false
    assert is_past_week?(~D[2019-10-30], "2019-11-06T23:59:59Z") == false
    assert is_past_week?(~D[2019-10-30], "2019-11-07T00:00:00Z") == true
    assert is_past_week?(~D[2019-10-30], "2019-11-07T00:00:01Z") == true
    assert is_past_week?(~D[2019-10-30], "2019-11-10T00:00:00Z") == true
  end

  def is_past_week?(date, dtim_str) do
    Mix.Tasks.Castle.Rollup.WeeklyUniques.is_past_week?(date, get_dtim(dtim_str))
  end
end
