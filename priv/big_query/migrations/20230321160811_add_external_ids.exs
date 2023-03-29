defmodule BigQuery.Migrations.AddExternalIds do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE campaigns ADD COLUMN integration_id INT64;
      ALTER TABLE campaigns ADD COLUMN external_id STRING;

      ALTER TABLE flights ADD COLUMN integration_id INT64;
      ALTER TABLE flights ADD COLUMN external_id STRING;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE campaigns DROP COLUMN integration_id;
      ALTER TABLE campaigns DROP COLUMN external_id;

      ALTER TABLE flights DROP COLUMN integration_id;
      ALTER TABLE flights DROP COLUMN external_id;
    """)
  end
end
