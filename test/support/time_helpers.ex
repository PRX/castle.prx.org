defmodule Castle.TimeHelpers do
  defmacro __using__(_opts) do
    quote do
      defp get_dtim(dtim_str) do
        format = case String.length(dtim_str) do
          8 -> "{YYYY}{0M}{0D}"
          10 -> "{YYYY}-{0M}-{0D}"
          _ -> "{ISO:Extended:Z}"
        end
        {:ok, dtim} = Timex.parse(dtim_str, format)
        dtim |> Timex.to_datetime()
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
