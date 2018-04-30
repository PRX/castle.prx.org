defmodule Mix.Tasks.Castle.Rollup.Totals do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "DEPRECATED: Manually calculate castle totals"

  @lock "lock.rollup.totals"
  @lock_ttl 60
  @success_ttl 60

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    if  Enum.member?(args, "--lock") || Enum.member?(args, "-l") do
      lock "#{@lock}.podcasts", @lock_ttl, @success_ttl, do: podcasts()
      lock "#{@lock}.episodes", @lock_ttl, @success_ttl, do: episodes()
    else
      podcasts()
      episodes()
    end
  end

  defp podcasts do
    Castle.Rollup.Jobs.Totals.run_podcasts() |> log("totals.podcasts")
  end

  defp episodes do
    Castle.Rollup.Jobs.Totals.run_episodes() |> log("totals.episodes")
  end

  defp log({_result, meta}, name) do
    case meta do
      %{job: _, total: _, megabytes: _} ->
        Logger.info "ROLLUP #{name} #{format_meta(meta)}"
      %{job: _} ->
        Logger.info "ROLLUP #{name} #{format_meta(meta)}"
      _ ->
        Logger.info "ROLLUP #{name} no changes"
    end
  end

  defp format_meta(%{cached: true} = meta) do
    base = Map.delete(meta, :cached) |> format_meta()
    "#{base} CACHED"
  end
  defp format_meta(%{job: jobs, total: total, megabytes: megabytes}) do
    "#{format_dates(jobs)} / #{total} total, #{megabytes} mb"
  end

  defp format_dates({nil, dtim}), do: "< #{format_date(dtim)}"
  defp format_dates({dtim, nil}), do: ">= #{format_date(dtim)}"
  defp format_dates({dtim1, dtim2}), do: "#{format_date(dtim1)} to #{format_date(dtim2)}"
  defp format_dates(nil), do: ""
  defp format_dates(jobs), do: Enum.map(jobs, &format_dates/1) |> Enum.join(", ")

  defp format_date(dtim) do
    {:ok, str} = Timex.format(dtim, "%Y-%m-%d", :strftime)
    str
  end
end
