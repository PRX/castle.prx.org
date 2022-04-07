defmodule BigQuery.Migrations.CreateMetadataTables do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE agentnames
      (
        agentname_id INT64 NOT NULL,
        tag STRING
      )
      OPTIONS(description="PRX Podagent tags");

      CREATE TABLE geonames
      (
        geoname_id INT64 NOT NULL,
        metro_code INT64,
        metro_name STRING,
        locale_code STRING,
        continent_code  STRING,
        continent_name  STRING,
        country_iso_code  STRING,
        country_name  STRING,
        subdivision_1_iso_code  STRING,
        subdivision_1_name  STRING,
        subdivision_2_iso_code  STRING,
        subdivision_2_name  STRING,
        city_name STRING,
        time_zone STRING
      )
      OPTIONS(description="Geonames");

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
        uuid STRING NOT NULL,
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
      DROP TABLE agentnames;
      DROP TABLE geonames;
      DROP TABLE podcasts;
      DROP TABLE episodes;
    """)
  end
end
