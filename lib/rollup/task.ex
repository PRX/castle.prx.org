defmodule Mix.Tasks.Castle.Rollup do
  use Mix.Task

  @shortdoc "Manually run the BigQuery data rollups"

  def run(_) do
    {:ok, _started} = Application.ensure_all_started(:castle)
    Castle.Rollup.Worker.run_jobs(%{log: true})
  end
end
