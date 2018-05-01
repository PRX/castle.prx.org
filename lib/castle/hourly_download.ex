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
    Enum.map(rows, &parse_row/1) |> insert_handle_conflict()
    length(rows)
  end

  defp insert_handle_conflict(rows), do: insert_handle_conflict(rows, actual_table(rows))
  defp insert_handle_conflict(rows, table) do
    try do
      Castle.Repo.insert_all table, rows, on_conflict: :replace_all, conflict_target: [:episode_id, :dtim]
    rescue
      e in Postgrex.Error ->
        case e do
          %{postgres: %{code: :undefined_table}} -> insert_handle_conflict(rows, Castle.HourlyDownload)
          %{postgres: %{code: :duplicate_table}} -> insert_handle_conflict(rows)
          _ -> raise e
        end
    end
  end

  defp parse_row(%{podcast_id: id, episode_guid: guid, hour: hour, count: count}) do
    %{podcast_id: id, episode_id: guid, dtim: hour, count: count}
  end

  defp actual_table([%{dtim: dtim} | _rest]) do
    {:ok, table_name} = Timex.format(dtim, "hourly_downloads_{YYYY}{0M}")
    {table_name, Castle.HourlyDownload}
  end
end
