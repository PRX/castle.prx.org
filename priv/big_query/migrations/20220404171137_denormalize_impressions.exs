defmodule BigQuery.Migrations.DenormalizeImpressions do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_impressions
      ADD COLUMN agent_name_id INT64,
      ADD COLUMN agent_type_id INT64,
      ADD COLUMN agent_os_id INT64,
      ADD COLUMN city_geoname_id INT64,
      ADD COLUMN country_geoname_id INT64,
      ADD COLUMN listener_id STRING;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_impressions
      DROP COLUMN agent_name_id INT64,
      DROP COLUMN agent_type_id INT64,
      DROP COLUMN agent_os_id INT64,
      DROP COLUMN city_geoname_id INT64,
      DROP COLUMN country_geoname_id INT64,
      DROP COLUMN listener_id STRING;
    """)
  end
end
