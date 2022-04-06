defmodule BigQuery.Migrations.BackfillGeonames do
  alias BigQuery.Base.Query
  alias BigQuery.Migrate.Utils

  def up do
    Enum.each(Utils.by_month("dt_downloads"), fn {start, stop} ->
      Query.log("""
        UPDATE dt_downloads
        SET geoname_id = COALESCE(city_geoname_id, country_geoname_id)
        WHERE geoname_id IS NULL
        AND (city_geoname_id IS NOT NULL OR country_geoname_id IS NOT NULL)
        AND timestamp >= "#{start}"
        AND timestamp < "#{stop}"
      """)
    end)
  end

  def down do
    Enum.each(Utils.by_month("dt_downloads"), fn {start, stop} ->
      Query.log("""
        UPDATE dt_downloads
        SET geoname_id = NULL
        WHERE geoname_id IS NOT NULL
        AND timestamp >= "#{start}"
        AND timestamp < "#{stop}"
      """)
    end)
  end
end
