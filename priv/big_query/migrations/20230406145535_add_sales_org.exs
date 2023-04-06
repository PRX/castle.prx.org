defmodule BigQuery.Migrations.AddSalesOrg do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE campaigns ADD COLUMN sales_org_name STRING;
      ALTER TABLE campaigns DROP COLUMN sales_rep_name;
      ALTER TABLE flights DROP COLUMN rep_name;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE campaigns DROP COLUMN sales_org_name;
      ALTER TABLE campaigns ADD COLUMN sales_rep_name STRING;
      ALTER TABLE flights ADD COLUMN rep_name STRING;
    """)
  end
end
