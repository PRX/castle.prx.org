defmodule BigQuery.Migrations.CreateGeonamesTmp do
  alias BigQuery.Base.Query

  def up do
    Query.log("""
      CREATE TABLE geonames_tmp
      (
        geoname_id INT64 NOT NULL,
        locale_code STRING,
        continent_code STRING,
        continent_name STRING,
        country_iso_code STRING,
        country_name STRING,
        subdivision_1_iso_code STRING,
        subdivision_1_name STRING,
        subdivision_2_iso_code STRING,
        subdivision_2_name STRING,
        city_name STRING,
        metro_code INT64,
        time_zone STRING,
        is_in_european_union BOOL
      )
      OPTIONS(description="Temporary geonames table for merging");
    """)
  end

  def down do
    Query.log("""
      DROP TABLE geonames_tmp;
    """)
  end
end
