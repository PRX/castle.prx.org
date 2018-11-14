defmodule Castle.Model.Partitioned do
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute __MODULE__, :partition_on, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :partition_unique, accumulate: false, persist: true

      # defaults
      @partition_on :day
      @partition_unique []

      def upsert(row), do: upsert_all([row])

      def upsert_all([]), do: 0
      def upsert_all(rows) when length(rows) > 5000 do
        Enum.chunk_every(rows, 5000)
        |> Enum.map(&upsert_all/1)
        |> Enum.sum()
      end
      def upsert_all(rows) do
        partition!(rows)
        Castle.Repo.insert_all __MODULE__, rows,
          on_conflict: :replace_all,
          conflict_target: get_attribute(:partition_unique)
        length(rows)
      end

      # create partitions based on timestamps
      defp partition!(rows) when is_list(rows) do
        rows
        |> Enum.map(&get_month/1)
        |> Enum.uniq
        |> Enum.map(&partition!/1)
      end
      defp partition!(start) do
        table = Ecto.get_meta struct(__MODULE__), :source
        stop = Timex.shift(start, months: 1)
        {:ok, part_str} = Timex.format(start, "{YYYY}{0M}")
        {:ok, start_str} = Timex.format(start, "{YYYY}-{0M}-{0D}")
        {:ok, stop_str} = Timex.format(stop, "{YYYY}-{0M}-{0D}")
        # IO.puts "CREATE TABLE IF NOT EXISTS #{table}_#{part_str}"
        Ecto.Adapters.SQL.query! Castle.Repo, """
          CREATE TABLE IF NOT EXISTS #{table}_#{part_str}
          PARTITION OF #{table}
          FOR VALUES FROM ('#{start_str}') TO ('#{stop_str}');
        """
      end

      defp get_month(row) do
        row
        |> Map.get(get_attribute(:partition_on))
        |> Timex.beginning_of_month
      end

      # get attribute from caller module, OR this one
      defp get_attribute(key) do
        case List.keyfind(__MODULE__.module_info(:attributes), key, 0) do
          {key, [val]} -> val
          {key, vals} -> vals
          _ -> nil
        end
      end
    end
  end
end
