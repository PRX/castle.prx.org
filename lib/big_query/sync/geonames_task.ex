defmodule Mix.Tasks.Bigquery.Sync.Geonames do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock
  alias NimbleCSV.RFC4180, as: CSV

  @shortdoc "Sync maxmind geonames to BigQuery"
  @lock "lock.bigquery.sync.geonames"
  @lock_ttl 120
  @success_ttl 30
  @url "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City-CSV&suffix=zip&license_key="
  @filename "GeoLite2-City-Locations-en.csv"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    lock = Enum.member?(args, "--lock") || Enum.member?(args, "-l")

    if lock do
      lock(@lock, @lock_ttl, @success_ttl, do: sync_geonames())
    else
      sync_geonames()
    end
  end

  defp sync_geonames do
    case get_maxmind_geonames() do
      {:ok, folder, count, data} ->
        dest = "#{Env.get(:bq_dataset)}.geonames_tmp"
        Logger.info("BigQuery.Sync.Geonames reload: #{dest} with #{count} rows from #{folder}")

        # create tmp table and load data into it
        BigQuery.Base.Query.run(create_table_sql("geonames_tmp"))
        {:ok, _msg} = BigQuery.Base.Load.reload("geonames_tmp", data)

        # merge tmp table into real geonames table
        {_, %{changed: changed}} =
          BigQuery.Base.Query.run(merge_table_sql("geonames_tmp", "geonames"))

        Logger.info("BigQuery.Sync.Geonames success: merged #{changed} new/updated rows")

        # cleanup
        BigQuery.Base.Query.run("DROP TABLE geonames_tmp")

      {:error, msg} ->
        Logger.error("BigQuery.Sync.Geonames error: #{msg}")
    end
  end

  defp get_maxmind_geonames do
    Logger.info("BigQuery.Sync.Geonames loading maxmind csv...")

    case Env.get(:maxmind_license_key) do
      nil -> {:error, "MAXMIND_LICENSE_KEY not set"}
      "" -> {:error, "MAXMIND_LICENSE_KEY not set"}
      key -> HTTPoison.get(@url <> key) |> parse_csv()
    end
  end

  defp parse_csv({:ok, %{status_code: 200, body: body}}) do
    {:ok, files} = :zip.list_dir(body)

    [folder, filename] =
      files
      |> Enum.filter(&(elem(&1, 0) == :zip_file))
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&to_string/1)
      |> Enum.find(&String.ends_with?(&1, @filename))
      |> String.split("/")

    file_list = [String.to_charlist("#{folder}/#{filename}")]
    {:ok, [{_, csv_str}]} = :zip.unzip(body, [{:file_list, file_list}, :memory])
    headers = csv_str |> String.split("\n", parts: 2) |> hd |> String.split(",")

    rows =
      csv_str
      |> CSV.parse_string()
      |> Enum.map(fn row -> Enum.zip(headers, row) |> Map.new() |> Jason.encode!() end)

    {:ok, folder, Enum.count(rows), Enum.join(rows, "\n")}
  end

  defp parse_csv({:ok, %{status_code: code}}), do: {:error, "got #{code} from maxmind"}
  defp parse_csv(err), do: {:error, inspect(err)}

  defp create_table_sql(table_name) do
    """
    CREATE TABLE IF NOT EXISTS #{table_name}
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
    );
    """
  end

  defp merge_table_sql(tmp_table_name, dest_table_name) do
    flds = ~w(locale_code continent_code continent_name country_iso_code country_name
      subdivision_1_iso_code subdivision_1_name subdivision_2_iso_code subdivision_2_name
      city_name metro_code time_zone is_in_european_union)

    changed = Enum.map(flds, &"dest.#{&1} != tmp.#{&1}") |> Enum.join(" OR ")
    sets = Enum.map(flds, &"#{&1} = tmp.#{&1}") |> Enum.join(", ")
    inserts = (["geoname_id"] ++ flds) |> Enum.join(", ")

    """
    MERGE #{dest_table_name} dest
    USING #{tmp_table_name} tmp
    ON dest.geoname_id = tmp.geoname_id
    WHEN MATCHED AND (#{changed}) THEN UPDATE SET #{sets}
    WHEN NOT MATCHED THEN INSERT(#{inserts}) VALUES(#{inserts})
    """
  end
end
