defmodule BigQuery.Migrations.CleanupGeonames do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN geoname_id INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN geoname_id;
    """)
  end
end
