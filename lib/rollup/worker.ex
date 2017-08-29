require Logger

defmodule Castle.Rollup.Worker do
  use GenServer

  @jobs [
    {Castle.Rollup.Jobs.Totals, :run, []},
  ]

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Application.get_env(:castle, :rollup_initial_delay) |> reschedule()
    {:ok, state}
  end

  def handle_info(:work, state) do
    run_jobs(state)
    Application.get_env(:castle, :rollup_delay) |> reschedule()
    {:noreply, state}
  end

  def run_jobs(state) do
    Enum.each @jobs, fn(job) -> run_job(job, state) end
  end

  defp reschedule(nil), do: nil
  defp reschedule(wait_seconds) do
    Process.send_after self(), :work, wait_seconds * 1000
  end

  defp run_job({module, name, args}, %{log: true}) do
    IO.puts "Running: #{module}"
    {_result, meta} = apply(module, name, args)
    if Map.has_key?(meta, :job) do
      IO.puts "  #{format_meta(meta)}"
    else
      IO.puts "  no partitions expired"
    end
  end

  defp run_job({module, name, args}, _state) do
    {_result, meta} = apply(module, name, args)
    if Map.has_key?(meta, :job) do
      Logger.debug "ROLLUP #{module} #{format_meta(meta)}"
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
