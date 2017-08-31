defmodule Castle.BigQueryBaseTimestampGroupTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Base.TimestampGroup

  defp test_group() do
    %BigQuery.Grouping{name: "foo", join: "whatever on (hello = world)",
      groupby: "your_group", limit: 1234}
  end

  test "joins the table" do
    sql = group_sql("the_table", "foo = @bar", test_group())
    assert sql =~ ~r/FROM the_table/
    assert sql =~ ~r/JOIN whatever on \(hello = world\)/
    assert sql =~ ~r/AND foo = @bar/
  end

  test "selects the display column" do
    sql = group_sql("the_table", "foo = @bar", test_group())
    assert sql =~ ~r/AS display/
  end

  test "sets params" do
    params = group_params(%{}, test_group())
    assert params.grouplimit == 1234
  end
end
