defmodule BigQuery.Migrations.AddZonesUnfilled do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_pre INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_mid INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_post INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_house_pre INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_house_mid INT64;
      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled_house_post INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_pre;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_mid;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_post;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_house_pre;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_house_mid;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled_house_post;
    """)
  end
end
