defmodule Castle.Rollup.Task do
  defmacro __using__(_opts) do
    quote do
      use Mix.Task
      import Castle.Redis.Lock
      require Logger

      Module.register_attribute __MODULE__, :interval, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :table, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :lock, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :lock_ttl, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :lock_success_ttl, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :default_count, accumulate: false, persist: true

      # defaults
      @interval "day"
      @table "does_not_exist"
      @lock "lock.rollup"
      @lock_ttl 50
      @lock_success_ttl 200
      @default_count 5

      def do_rollup(args, work_fn) when is_list(args) do
        Enum.into(args, %{}) |> do_rollup(work_fn)
      end
      def do_rollup(%{lock: true} = args, work_fn) do
        lock = get_attribute(:lock)
        lock_ttl = get_attribute(:lock_ttl)
        success_ttl = get_attribute(:lock_success_ttl)
        find_rollup_logs(args) |> Enum.map(fn(log) ->
          lock "#{lock}.#{log.date}", lock_ttl, success_ttl, do: work_fn.(log)
        end)
      end
      def do_rollup(args, work_fn) do
        find_rollup_logs(args) |> Enum.map(&(work_fn.(&1)))
      end

      # get attribute from caller module, OR this one
      def get_attribute(key) do
        case List.keyfind(__MODULE__.module_info(:attributes), key, 0) do
          {key, [val]} -> val
          _ -> nil
        end
      end

      defp find_rollup_logs(%{date: date_str}) do
        [%Castle.RollupLog{table_name: table_name(), date: parse_date(date_str)}]
      end
      defp find_rollup_logs(%{count: count}) do
        case get_attribute(:interval) do
          "month" -> Castle.RollupLog.find_missing_months table_name(), count
          "week" -> Castle.RollupLog.find_missing_weeks table_name(), count
          "day" -> Castle.RollupLog.find_missing_days table_name(), count
        end
      end
      defp find_rollup_logs(_opts), do: find_rollup_logs(%{count: get_attribute(:default_count)})

      defp set_complete(rollup_log) do
        rollup_log |> Map.put(:complete, true) |> Castle.RollupLog.upsert!()
      end

      defp set_incomplete(rollup_log) do
        rollup_log |> Map.put(:complete, false) |> Castle.RollupLog.upsert!()
      end

      defp table_name do
        get_attribute(:table)
      end

      defp parse_date(str) do
        format = case String.length(str) do
          10 -> "{YYYY}-{0M}-{0D}"
          8 -> "{YYYY}{0M}{0D}"
          _ -> "{ISO:Extended}"
        end
        case Timex.parse(str, format) do
          {:ok, dtim} ->
            case get_attribute(:interval) do
              "month" -> dtim |> Timex.beginning_of_month |> Timex.to_date
              "day" -> dtim |> Timex.beginning_of_day |> Timex.to_date
              _ -> dtim |> Timex.to_date
            end
          _ -> raise "Invalid date provided: #{str}"
        end
      end

      def is_past_month?(date, now \\ Timex.now) do
        offset = Timex.shift(now, months: -1, days: -1)
        Timex.compare(offset, date) > -1
      end
    end
  end
end
