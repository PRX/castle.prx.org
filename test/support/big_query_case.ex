defmodule Castle.BigQueryCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp interval(from_str, to_str, rollup) do
        {:ok, start, _} = DateTime.from_iso8601(from_str)
        {:ok, finish, _} = DateTime.from_iso8601(to_str)
        %{from: start, to: finish, rollup: rollup}
      end

      defp assert_time(result, index, expected_str) do
        {:ok, expected, _} = DateTime.from_iso8601(expected_str)
        {:ok, format_expected} = Timex.format(expected, "{ISO:Extended:Z}")
        {:ok, format_result} = Timex.format(Enum.at(result, index).time, "{ISO:Extended:Z}")
        assert format_result == format_expected
      end

      defp mutate_dtim(dtim_str, mutate_fn) do
        {:ok, dtim, _} = DateTime.from_iso8601(dtim_str)
        {:ok, formatted} = Timex.format(mutate_fn.(dtim), "{ISO:Extended:Z}")
        formatted
      end

      defp mutate_dtims(dtim_str1, dtim_str2, mutate_fn) do
        {:ok, dtim1, _} = DateTime.from_iso8601(dtim_str1)
        {:ok, dtim2, _} = DateTime.from_iso8601(dtim_str2)
        mutate_fn.(dtim1, dtim2) |> Enum.map(fn(dtim) ->
          {:ok, formatted} = Timex.format(dtim, "{ISO:Extended:Z}")
          formatted
        end)
      end

      defp call_dtims(dtim_str1, dtim_str2, call_fn) do
        {:ok, dtim1, _} = DateTime.from_iso8601(dtim_str1)
        {:ok, dtim2, _} = DateTime.from_iso8601(dtim_str2)
        call_fn.(dtim1, dtim2)
      end
    end
  end
end
