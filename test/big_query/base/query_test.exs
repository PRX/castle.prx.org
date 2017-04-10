defmodule Porter.BigQueryBaseQueryTest do
  use Porter.BigQueryCase, async: true

  import BigQuery.Base.Query

  @tag :external
  test "queries with a plain string" do
    {result, meta} = query("""
      SELECT * FROM #{Env.get(:bq_impressions_table)}
      WHERE is_duplicate = true
      LIMIT 2
    """)

    assert is_list result
    assert length(result) == 2
    assert hd(result).is_duplicate == true
    assert is_map meta
    assert is_boolean meta.cached
    assert meta.bytes >= 0
    assert meta.megabytes >= 0
    assert meta.total == 2
  end

  @tag :external
  test "queries with parameters" do
    {result, meta} = query("""
      SELECT * FROM #{Env.get(:bq_impressions_table)}
      WHERE is_duplicate = @is_dup
      LIMIT @lim
    """, %{is_dup: true, lim: 2})

    assert is_list result
    assert length(result) == 2
    assert hd(result).is_duplicate == true
    assert is_map meta
    assert is_boolean meta.cached
    assert meta.bytes >= 0
    assert meta.megabytes >= 0
    assert meta.total == 2
  end
end
