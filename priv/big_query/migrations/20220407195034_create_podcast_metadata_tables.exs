defmodule BigQuery.Migrations.CreatePodcastMetadataTables do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE podcasts
      (
        id INT64 NOT NULL,
        account_id INT64,
        title STRING,
        subtitle STRING,
        image_url STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        published_at TIMESTAMP,
        deleted_at TIMESTAMP
      )
      OPTIONS(description="Feeder podcasts");

      CREATE TABLE episodes
      (
        id STRING NOT NULL,
        podcast_id INT64,
        title STRING,
        subtitle STRING,
        image_url STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP,
        published_at TIMESTAMP,
        released_at TIMESTAMP,
        deleted_at TIMESTAMP,
        segment_count INT64,
        audio_version STRING,
        keywords ARRAY<STRING>
      )
      OPTIONS(description="Feeder episodes");
    """)
  end

  def down do
    Query.log("""
      DROP TABLE podcasts;
      DROP TABLE episodes;
    """)
  end
end
