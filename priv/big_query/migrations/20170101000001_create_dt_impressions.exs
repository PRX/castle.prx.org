defmodule BigQuery.Migrations.CreateDtImpressions do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE dt_impressions
      (
        timestamp TIMESTAMP NOT NULL,
        request_uuid STRING NOT NULL,
        feeder_podcast INT64,
        feeder_episode STRING,
        is_duplicate BOOL,
        cause STRING,
        ad_id INT64,
        campaign_id INT64,
        creative_id INT64,
        flight_id INT64,
        is_confirmed BOOL,
        is_bytes BOOL,
        digest STRING,
        listener_session STRING,
        segment INT64,
        placements_key STRING,
        zone_name STRING,
        target_path STRING
      )
      PARTITION BY DATE(timestamp)
      OPTIONS(
        require_partition_filter=true,
        description="Dovetail impressions"
      )
    """)
  end

  def down do
    raise "WOH- you should never delete dt_impressions!"
  end
end
