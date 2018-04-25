defmodule Castle.TimeHelpers do
  defmacro __using__(_opts) do
    quote do
      defp get_dtim(dtim_str) do
        case DateTime.from_iso8601(dtim_str) do
          {:ok, dtim, _} -> dtim
          _ -> nil
        end
      end

      defp format_dtim(dtim) do
        case Timex.format(dtim, "{ISO:Extended:Z}") do
          {:ok, formatted} -> String.replace(formatted, ".000000Z", "Z")
          _ -> "ERROR - BAD DATE"
        end
      end

      defp assert_time(list, idx, exp), do: assert_time(Enum.at(list, idx), exp)
      defp assert_time(%{time: time}, expected_str), do: assert_time(time, expected_str)
      defp assert_time(time, expected_str) do
        assert format_dtim(time) == expected_str
      end
    end
  end
end
