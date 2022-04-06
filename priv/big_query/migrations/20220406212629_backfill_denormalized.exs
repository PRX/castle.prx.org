defmodule BigQuery.Migrations.BackfillDenormalized do
  alias BigQuery.Base.Query
  alias BigQuery.Migrate.Utils

  def up do
    Enum.each(Utils.by_month("dt_impressions"), fn {start, stop} ->
      Query.log("""
        UPDATE dt_impressions i
        SET i.agent_name_id = d.agent_name_id,
            i.agent_type_id = d.agent_type_id,
            i.agent_os_id = d.agent_os_id,
            i.geoname_id = d.geoname_id,
            i.listener_id = d.listener_id
        FROM (#{distinct_downloads(start, stop)}) d
        WHERE i.request_uuid = d.request_uuid
        AND timestamp >= "#{start}"
        AND timestamp < "#{stop}"
      """)
    end)
  end

  def down do
    Enum.each(Utils.by_month("dt_impressions"), fn {start, stop} ->
      Query.log("""
        UPDATE dt_impressions
        SET agent_name_id = NULL,
            agent_type_id = NULL,
            agent_os_id = NULL,
            geoname_id = NULL,
            listener_id = NULL
        WHERE timestamp >= "#{start}"
        AND timestamp < "#{stop}"
      """)
    end)
  end

  defp distinct_downloads(start, stop) do
    """
      SELECT
        request_uuid,
        ANY_VALUE(agent_name_id) AS agent_name_id,
        ANY_VALUE(agent_type_id) AS agent_type_id,
        ANY_VALUE(agent_os_id) AS agent_os_id,
        ANY_VALUE(geoname_id) AS geoname_id,
        ANY_VALUE(listener_id) AS listener_id,
      FROM dt_downloads
      WHERE timestamp > "#{Date.add(start, -1)}" and timestamp < "#{Date.add(stop, 1)}"
      GROUP BY request_uuid
    """
  end
end
