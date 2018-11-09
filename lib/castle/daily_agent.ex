defmodule Castle.DailyAgent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "daily_agents" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :agent_name_id, :integer
    field :agent_type_id, :integer
    field :agent_os_id, :integer
    field :day, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day, :count])
    |> validate_required([:podcast_id, :episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day, :count])
  end

  def upsert(row), do: upsert_all([row])

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 10000 do
    Enum.chunk_every(rows, 10000)
    |> Enum.map(&upsert_all/1)
    |> Enum.sum()
  end
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.DailyAgent, rows, on_conflict: :replace_all,
      conflict_target: [:episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day]
    length(rows)
  end
end
