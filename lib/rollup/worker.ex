require Logger

defmodule Castle.Rollup.Worker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{jobs: [
      {Castle.Rollup.Jobs.Totals, :run, []},
    ]})
  end

  def init(state) do
    Application.get_env(:castle, :rollup_initial_delay) |> reschedule()
    {:ok, state}
  end

  defp reschedule(nil), do: nil
  defp reschedule(wait_seconds) do
    Process.send_after self(), :work, wait_seconds * 1000
  end

  def handle_info(:work, state) do
    Enum.each(state.jobs, &run_job/1)
    Application.get_env(:castle, :rollup_delay) |> reschedule()
    {:noreply, state}
  end

  defp run_job({module, name, args}) do
    {_result, meta} = apply(module, name, args)
    log_meta(module, meta)
  end

  defp log_meta(module, %{job: jobs, total: total, megabytes: megabytes} = meta) do
    dates = jobs |> Enum.map(&format_dates/1) |> Enum.join(", ")
    if meta.cached do
      Logger.debug "ROLLUP #{module} #{dates} - #{total} total, #{megabytes} mb CACHED"
    else
      Logger.info "ROLLUP #{module} #{dates} - #{total} total, #{megabytes} mb"
    end
  end
  defp log_meta(_module, _meta), do: nil

  defp format_dates({nil, dtim}), do: "< #{format_date(dtim)}"
  defp format_dates({dtim, nil}), do: ">= #{format_date(dtim)}"
  defp format_dates({dtim1, dtim2}), do: "#{format_date(dtim1)} to #{format_date(dtim2)}"

  defp format_date(dtim) do
    {:ok, str} = Timex.format(dtim, "%Y-%m-%d", :strftime)
    str
  end
end
