defmodule BigQuery.Migrations.CreateCampaignMetadataTables do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE advertisers
      (
        id INT64 NOT NULL,
        name STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury advertisers");

      CREATE TABLE campaigns
      (
        id INT64 NOT NULL,
        account_id INT64,
        advertiser_id INT64,
        name STRING,
        type STRING,
        rep_name STRING,
        sales_rep_name STRING,
        notes STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury campaigns");

      CREATE TABLE creatives
      (
        id INT64 NOT NULL,
        account_id INT64,
        advertiser_id INT64,
        url STRING,
        mime_type STRING,
        file_size INT64,
        filename STRING,
        media_type STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury creatives");

      CREATE TABLE flights
      (
        id INT64 NOT NULL,
        campaign_id INT64,
        podcast_id INT64,
        name STRING,
        rep_name STRING,
        notes STRING,
        status STRING,
        start_at TIMESTAMP,
        end_at TIMESTAMP,
        total_goal INT64,
        contract_start_at TIMESTAMP,
        contract_end_at TIMESTAMP,
        contract_goal INT64,
        allocation_priority INT64,
        delivery_mode STRING,
        is_companion BOOL,
        daily_minimum INT64,
        velocity STRING,
        unique_per_campaign BOOL,
        unique_per_advertiser BOOL,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury flights");

      CREATE TABLE placements
      (
        id INT64 NOT NULL,
        podcast_id INT64,
        name STRING,
        original_count INT64,
        zone_index INT64,
        zone_type STRING,
        zone_name STRING,
        zone_label STRING,
        section_name STRING,
        section_label STRING,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
      OPTIONS(description="Augury placements");
    """)
  end

  def down do
    Query.log("""
      DROP TABLE advertisers;
      DROP TABLE campaigns;
      DROP TABLE creatives;
      DROP TABLE flights;
      DROP TABLE placements;
    """)
  end
end
