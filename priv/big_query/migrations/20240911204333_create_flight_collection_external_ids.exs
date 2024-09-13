defmodule BigQuery.Migrations.CreateFlightCollectionExternalIds do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE flight_collection_external_ids
      (
        id INT64 NOT NULL,
        flight_id INT64,
        podcast_id INT64,
        external_id STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury Flight Collection External IDs");
    """)
  end

  def down do
    Query.log("""
      DROP TABLE flight_collection_external_ids;
    """)
  end
end
