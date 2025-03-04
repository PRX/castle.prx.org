defmodule BigQuery.Migrations.AddFlightParentIds do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE flights ADD COLUMN collection_id INT64;
      ALTER TABLE flights ADD COLUMN parent_id INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE flights DROP COLUMN collection_id;
      ALTER TABLE flights DROP COLUMN parent_id;
    """)
  end
end
