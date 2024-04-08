defmodule BigQuery.Migrations.AddPricing do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE campaigns ADD COLUMN budget_model STRING;
      ALTER TABLE campaigns ADD COLUMN budget_cents INT64;
      ALTER TABLE campaigns ADD COLUMN budget_currency STRING;

      ALTER TABLE flights ADD COLUMN price_model STRING;
      ALTER TABLE flights ADD COLUMN price_cents INT64;
      ALTER TABLE flights ADD COLUMN price_currency STRING;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE campaigns DROP COLUMN budget_model STRING;
      ALTER TABLE campaigns DROP COLUMN budget_cents INT64;
      ALTER TABLE campaigns DROP COLUMN budget_currency STRING;

      ALTER TABLE flights DROP COLUMN price_model STRING;
      ALTER TABLE flights DROP COLUMN price_cents INT64;
      ALTER TABLE flights DROP COLUMN price_currency STRING;
    """)
  end
end
