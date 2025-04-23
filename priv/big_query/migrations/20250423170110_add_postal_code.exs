defmodule BigQuery.Migrations.AddPostalCode do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN postal_code STRING;
      ALTER TABLE dt_impressions ADD COLUMN postal_code STRING;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN postal_code;
      ALTER TABLE dt_impressions DROP COLUMN postal_code;
    """)
  end
end
