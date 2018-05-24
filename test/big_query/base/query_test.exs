defmodule Castle.BigQueryBaseQueryTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.Base.Query

  @tag :external
  test "queries with a plain string" do
    {result, meta} = query("""
      SELECT request_uuid, timestamp, is_duplicate FROM dt_downloads
      WHERE is_duplicate = true
      AND EXTRACT(DATE FROM timestamp) = '2017-10-29'
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
    {result, meta} = query(%{is_dup: true, lim: 2}, """
      SELECT request_uuid, timestamp, is_duplicate FROM dt_downloads
      WHERE is_duplicate = @is_dup
      AND EXTRACT(DATE FROM timestamp) = '2017-10-29'
      LIMIT @lim
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
  test "loads all pages of results" do
    {result, meta} = query(%{is_dup: true, lim: 215}, """
      SELECT request_uuid, timestamp, is_duplicate FROM dt_downloads
      WHERE is_duplicate = @is_dup
      AND EXTRACT(DATE FROM timestamp) = '2017-10-29'
      LIMIT @lim
    """, 100)

    assert is_list result
    assert length(result) == 215
    assert meta.bytes >= 0
    assert meta.megabytes >= 0
    assert meta.total == 215
  end
end
