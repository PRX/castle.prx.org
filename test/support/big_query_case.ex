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
    end
  end
end
