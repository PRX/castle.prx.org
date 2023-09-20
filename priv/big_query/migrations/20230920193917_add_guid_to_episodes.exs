defmodule BigQuery.Migrations.AddGuidToEpisodes do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE episodes ADD COLUMN guid STRING;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE episodes DROP COLUMN guid;
    """)
  end
end
