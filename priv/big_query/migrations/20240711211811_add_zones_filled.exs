defmodule BigQuery.Migrations.AddZonesFilled do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_pre INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_mid INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_post INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_house_pre INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_house_mid INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_filled_house_post INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_pre;
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_mid;
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_post;
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_house_pre;
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_house_mid;
      ALTER TABLE dt_downloads DROP COLUMN zones_filled_house_post;
    """)
  end
end
