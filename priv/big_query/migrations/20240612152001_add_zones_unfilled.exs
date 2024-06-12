defmodule BigQuery.Migrations.AddPricing do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      ALTER TABLE dt_downloads ADD COLUMN zones_filled STRUCT<
        pre INT64,
        mid INT64,
        post INT64,
        house_pre INT64,
        house_mid INT64,
        house_post INT64
      >;

      ALTER TABLE dt_downloads ADD COLUMN zones_unfilled STRUCT<
        pre INT64,
        mid INT64,
        post INT64,
        house_pre INT64,
        house_mid INT64,
        house_post INT64
      >;
    """)
  end

  def down do
    Query.log("""
      ALTER TABLE dt_downloads DROP COLUMN zones_filled;
      ALTER TABLE dt_downloads DROP COLUMN zones_unfilled;
    """)
  end
end
