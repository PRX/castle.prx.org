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

      # TODO: is there some way to check the _latest version_ we've loadedd into geonames?
      # maybe the description of the table? or what?
      # TODO: load into a temporary table
      # TODO: then run a MERGE on it https://cloud.google.com/bigquery/docs/reference/standard-sql/dml-syntax#merge_statement
      # case BigQuery.Base.Load.reload("geonames_tmp", data) do
      #   {:ok, msg} -> Logger.info("BigQuery.Sync.Geonames success: #{msg}")
      #   {:error, msg} -> Logger.error("BigQuery.Sync.Geonames error: #{msg}")
      # end

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

  defp format_tags({:ok, json}) do
    tags = Map.get(json, "tags", [])
    formatted = Enum.map(tags, fn {id, tag} -> %{agentname_id: id, tag: tag} end)
    {:ok, formatted}
  end

  defp format_tags(err), do: err
end
