defmodule BigQuery.Migrations.CreateDtDownloads do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE dt_downloads
      (
        timestamp TIMESTAMP,
        request_uuid STRING,
        feeder_podcast INT64,
        feeder_episode STRING,
        program STRING,
        path STRING,
        clienthash STRING,
        digest STRING,
        ad_count INT64,
        is_duplicate BOOL,
        cause STRING,
        remote_referrer STRING,
        remote_agent STRING,
        remote_ip STRING,
        agent_name_id INT64,
        agent_type_id INT64,
        agent_os_id INT64,
        city_geoname_id INT64,
        country_geoname_id INT64,
        postal_code STRING,
        latitude FLOAT64,
        longitude FLOAT64,
        is_confirmed BOOL,
        is_bytes BOOL,
        url STRING,
        listener_id STRING,
        listener_episode STRING,
        listener_session STRING
      )
      PARTITION BY DATE(timestamp)
      OPTIONS(
        require_partition_filter=true,
        description="Dovetail downloads"
      )
    """)
  end

  def down do
    raise "WOH- you should never delete dt_downloads!"
  end
end
