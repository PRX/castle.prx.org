defmodule BigQuery.Migrations.AddFeederFeeds do
  alias BigQuery.Base.Query

  def up do
    Query.log("ALTER TABLE dt_downloads ADD COLUMN feeder_feed STRING")
    Query.log("ALTER TABLE dt_impressions ADD COLUMN feeder_feed STRING")
  end

  def down do
    Query.log("ALTER TABLE dt_downloads DROP COLUMN feeder_feed")
    Query.log("ALTER TABLE dt_impressions DROP COLUMN feeder_feed")
  end
end
