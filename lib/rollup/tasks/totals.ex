defmodule Mix.Tasks.Castle.Rollup.Totals do
  use Mix.Task
  require Logger

  @shortdoc "Manually calculate castle totals"

  def run(_args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    Logger.info "Rollup.Totals updating"
    pods = Castle.HourlyDownload.set_podcast_totals!
    eps = Castle.HourlyDownload.set_episode_totals!
    Logger.info "Rollup.Totals finished #{pods} podcasts / #{eps} episodes"
  end
end
