defmodule Castle.Repo.Migrations.AddFeederDeletedAt do
  use Ecto.Migration

  def change do
    alter table(:podcasts) do
      add(:deleted_at, :utc_datetime)
    end

    alter table(:episodes) do
      add(:deleted_at, :utc_datetime)
    end
  end
end
