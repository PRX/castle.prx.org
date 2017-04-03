defmodule Porter.BigQueryBaseQueryTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Base.Query

  @tag :external
  test "queries with a plain string" do
    result = query("""
      SELECT * FROM #{Env.get(:bq_impressions_table)}
      WHERE is_duplicate = true
      LIMIT 2
    """)

    assert is_list result
    assert length(result) == 2
    assert hd(result).is_duplicate == true
  end

  @tag :external
  test "queries with parameters" do
    result = query("""
      SELECT * FROM #{Env.get(:bq_impressions_table)}
      WHERE is_duplicate = @is_dup
      LIMIT @lim
    """, %{is_dup: true, lim: 2})

    assert is_list result
    assert length(result) == 2
    assert hd(result).is_duplicate == true
  end
end
