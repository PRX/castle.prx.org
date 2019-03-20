Code.require_file "20180530194450_create_daily_agents.exs", Path.dirname(__ENV__.file)

defmodule Castle.Repo.Migrations.RePartitionAgents do
  use Ecto.Migration

  alias Castle.Repo.Migrations.CreateDailyAgents

  def up do
    CreateDailyAgents.down()
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_agents'"
    execute """
      CREATE TABLE daily_agents (
        podcast_id integer NOT NULL,
        episode_id uuid NOT NULL,
        agent_name_id integer NOT NULL DEFAULT 0,
        agent_type_id integer NOT NULL DEFAULT 0,
        agent_os_id integer NOT NULL DEFAULT 0,
        day date NOT NULL,
        count integer NOT NULL,
        PRIMARY KEY (episode_id, agent_name_id, agent_type_id, agent_os_id, day)
      ) PARTITION BY RANGE (day);
    """
    create index(:daily_agents, [:podcast_id, :agent_name_id, :agent_type_id, :agent_os_id, :day])
  end

  def down do
    drop table(:daily_agents)
    execute "DELETE FROM rollup_logs WHERE table_name = 'daily_agents'"
    CreateDailyAgents.up()
  end
end
