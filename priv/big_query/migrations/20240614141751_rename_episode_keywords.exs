defmodule BigQuery.Migrations.RenameEpisodeKeywords do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE episodes RENAME COLUMN keywords TO categories;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE episodes RENAME COLUMN categories TO keywords;
    """)
  end
end
