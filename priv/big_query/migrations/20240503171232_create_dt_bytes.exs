defmodule BigQuery.Migrations.CreateDtBytes do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE dt_bytes
      (
        day DATE,
        feeder_podcast INT64,
        feeder_feed STRING,
        feeder_episode STRING,
        bytes INT64
      )
      PARTITION BY DATE_TRUNC(day, MONTH)
      OPTIONS(
        require_partition_filter=true,
        description="Dovetail CDN bytes usage"
      )
    """)
  end

  def down do
    raise "WOH- you should never delete dt_bytes!"
  end
end
