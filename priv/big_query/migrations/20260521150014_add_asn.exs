defmodule BigQuery.Migrations.AddAsn do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN asn INT64;
      ALTER TABLE dt_impressions ADD COLUMN asn INT64;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN asn;
      ALTER TABLE dt_impressions DROP COLUMN asn;
    """)
  end
end
