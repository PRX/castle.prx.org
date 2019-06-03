defmodule Castle.BigQueryCase do
  use ExUnit.CaseTemplate, async: false

  defmacro test_with_bq(name, mock_result, do: expression) do
    quote do
      test_with_bq unquote(name), nil, unquote(mock_result), do: unquote(expression)
    end
  end
  defmacro test_with_bq(name, now_str, mock_result, do: expression) do
    quote do
      test unquote(name) do
        query = fn(_params, _sql) ->
          data = unquote(mock_result)
          {data, %{bytes: 1, megabytes: 1, cached: false, total: length(data)}}
        end
        query_each = fn(_params, _sql, func) ->
          data = unquote(mock_result)
          func.(data)
          %{bytes: 1, megabytes: 1, cached: false, total: length(data)}
        end
        with_mock BigQuery.Base.Query, [query: query, query_each: query_each] do
          if unquote(now_str) do
            now = [now: fn() -> get_dtim(unquote(now_str)) end]
            with_mock Timex, [:passthrough], now, do: unquote(expression)
          else
            unquote(expression)
          end
        end
      end
    end
  end

  using do
    quote do
      import Mock
      import Castle.BigQueryCase
      use Castle.TimeHelpers

      defp interval(from_str, to_str, rollup) do
        {:ok, start, _} = DateTime.from_iso8601(from_str)
        {:ok, finish, _} = DateTime.from_iso8601(to_str)
        %{from: start, to: finish, rollup: rollup}
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
