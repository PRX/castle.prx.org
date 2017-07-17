defmodule Castle.BigQueryCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      defp interval(from_str, to_str, seconds) do
        {:ok, start, _} = DateTime.from_iso8601(from_str)
        {:ok, finish, _} = DateTime.from_iso8601(to_str)
        %{from: start, to: finish, seconds: seconds}
      end

      defp assert_time(result, index, expected_str) do
        {:ok, expected, _} = DateTime.from_iso8601(expected_str)
        assert Timex.format(Enum.at(result, index).time, "{ISO:Extended:Z}")
          == Timex.format(expected, "{ISO:Extended:Z}")
      end
    end
  end
end
