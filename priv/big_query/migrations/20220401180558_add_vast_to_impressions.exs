defmodule BigQuery.Migrations.AddVastToImpressions do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_impressions
      ADD COLUMN vast_advertiser STRING,
      ADD COLUMN vast_ad_id STRING,
      ADD COLUMN vast_creative_id STRING,
      ADD COLUMN vast_price_value NUMERIC,
      ADD COLUMN vast_price_currency STRING,
      ADD COLUMN vast_price_model STRING
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_impressions
      DROP COLUMN vast_advertiser,
      DROP COLUMN vast_ad_id,
      DROP COLUMN vast_creative_id,
      DROP COLUMN vast_price_value,
      DROP COLUMN vast_price_currency,
      DROP COLUMN vast_price_model
    """)
  end
end
