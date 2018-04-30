defmodule Castle.HourlyDownload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "hourly_downloads" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :dtim, :utc_datetime
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :dtim, :count])
    |> validate_required([:podcast_id, :episode_id, :dtim, :count])
  end

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 5000 do
    Enum.chunk_every(rows, 5000)
    |> Enum.map(&upsert_all/1)
    |> Enum.sum()
  end
  def upsert_all(rows) do
    try do
      insert_handle_conflict(actual_table(rows), rows)
    rescue
      e in Postgrex.Error ->
        case e do
          %{postgres: %{code: :undefined_table}} -> insert_handle_conflict(Castle.HourlyDownload, rows)
          _ -> raise e
        end
    end
    length(rows)
  end

  defp insert_handle_conflict(table, raw_rows) do
    rows = Enum.map(raw_rows, &parse_row/1)
    uniq = [:episode_id, :dtim]
    Castle.Repo.insert_all table, rows, on_conflict: :replace_all, conflict_target: uniq
  end

  defp parse_row(%{podcast_id: id, episode_guid: guid, hour: hour, count: count}) do
    %{podcast_id: id, episode_id: guid, dtim: hour, count: count}
  end

  defp actual_table([%{hour: hour} | _rest]) do
    {:ok, table_name} = Timex.format(hour, "hourly_downloads_{YYYY}{0M}")
    {table_name, Castle.HourlyDownload}
  end
end
