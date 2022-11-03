defmodule BigQuery.Migrations.AddFlightCreatives do
  alias BigQuery.Base.Query

  def up do
    Query.log("ALTER TABLE flights ADD COLUMN creative_ids ARRAY<INT64>")
  end

  def down do
    Query.log("ALTER TABLE flights DROP COLUMN creative_ids")
  end
end
