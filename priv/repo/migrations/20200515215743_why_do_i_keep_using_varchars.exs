defmodule Castle.Repo.Migrations.WhyDoIKeepUsingVarchars do
  use Ecto.Migration

  def up do
    alter table(:podcasts) do
      modify(:title, :text)
    end

    alter table(:episodes) do
      modify(:title, :text)
      modify(:audio_version, :text)
    end
  end

  def down do
    alter table(:podcasts) do
      modify(:title, :string)
    end

    alter table(:episodes) do
      modify(:title, :string)
      modify(:audio_version, :string)
    end
  end
end
