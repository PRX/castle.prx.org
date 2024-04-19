defmodule Mix.Tasks.Bigquery.Sync.Geonames do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock
  alias NimbleCSV.RFC4180, as: CSV

  @shortdoc "Sync maxmind geonames to BigQuery"
  @lock "lock.bigquery.sync.geonames"
  @lock_ttl 120
  @success_ttl 30
  @url "https://download.maxmind.com/geoip/databases/GeoLite2-City-CSV/download?suffix=zip"
  @filename "GeoLite2-City-Locations-en.csv"
  @max_redirects 3

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

        # load data into "temporary" table
        {:ok, _msg} = BigQuery.Base.Load.reload("geonames_tmp", data)

        # merge tmp table into real geonames table
        {_, %{changed: changed}} =
          BigQuery.Base.Query.run(merge_table_sql("geonames_tmp", "geonames"))

        Logger.info("BigQuery.Sync.Geonames success: merged #{changed} new/updated rows")

      {:error, msg} ->
        Logger.error("BigQuery.Sync.Geonames error: #{msg}")
    end
  end

  defp get_maxmind_geonames do
    Logger.info("BigQuery.Sync.Geonames loading maxmind csv...")

    case {Env.get(:maxmind_account_id), Env.get(:maxmind_license_key)} do
      {nil, _} -> {:error, "MAXMIND_ACCOUNT_ID not set"}
      {"", _} -> {:error, "MAXMIND_ACCOUNT_ID not set"}
      {_, nil} -> {:error, "MAXMIND_LICENSE_KEY not set"}
      {_, ""} -> {:error, "MAXMIND_LICENSE_KEY not set"}
      {user, pass} -> get_csv(@url, follow_redirect: false, hackney: [basic_auth: {user, pass}])
    end
  end

  defp get_csv(url, opts, followed_redirects \\ 0) do
    if followed_redirects >= @max_redirects do
      {:error, "hit max redirects on #{url}"}
    else
      case HTTPoison.get(url, [], opts) do
        {:ok, %{status_code: 200, body: body}} ->
          parse_csv(body)

        # NOTE: follow_redirects: true includes basic auth in subsequent requests, which
        # results in 400s on the signed redirect urls
        {:ok, %{status_code: 302, headers: headers}} ->
          {_, location} = List.keyfind(headers, "Location", 0)
          get_csv(location, [follow_redirect: false], followed_redirects + 1)

        {:ok, %{status_code: code}} ->
          {:error, "got #{code} from maxmind"}

        err ->
          {:error, inspect(err)}
      end
    end
  end

  defp parse_csv(body) do
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
