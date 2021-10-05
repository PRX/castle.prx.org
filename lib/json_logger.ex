defmodule Castle.JsonLogger do
  require Logger

  @exclude_meta [
    :pid,
    :line,
    :function,
    :module,
    :file,
    :application,
    :gl,
    :mfa,
    :domain,
    :report_cb,
    :erl_level,
    :time
  ]

  def format(level, message, timestamp, metadata) do
    time = format_time(timestamp)
    level = Atom.to_string(level)
    levelpad = String.duplicate(" ", 5 - String.length(level))
    msg = format_message(message)
    meta = format_meta(metadata)

    """
    {"time":"#{time}","level":"#{level}",#{levelpad}#{msg}#{meta}}
    """
  rescue
    _ -> "ERROR: Unable to format: #{inspect({level, message, timestamp, metadata})}\n"
  end

  defp format_time({date, {hh, mm, ss, ms}}) do
    case NaiveDateTime.from_erl({date, {hh, mm, ss}}, {ms * 1000, 3}) do
      {:ok, timestamp} -> NaiveDateTime.to_iso8601(timestamp) <> "Z"
      _ -> nil
    end
  end

  defp format_message(data) when is_list(data) do
    msg = String.Chars.to_string(data) |> String.replace("\n", "")
    json_encode("msg", msg)
  end

  defp format_message("" <> data), do: json_encode("msg", data)

  defp format_message(data), do: json_encode("msg", inspect(data))

  defp format_meta(meta) when is_list(meta) do
    meta |> Enum.into(%{}) |> Map.drop(@exclude_meta) |> format_meta()
  end

  defp format_meta(meta) when is_map(meta) and meta != %{} do
    "," <> Enum.join(Enum.map(meta, &json_encode/1), ",")
  end

  defp format_meta(_), do: ""

  defp json_encode({key, val}), do: json_encode(key, val)

  defp json_encode(:error, {:error, val}), do: json_encode(:error, val)

  defp json_encode(key, val) do
    case {Jason.encode(key), Jason.encode(val)} do
      {{:ok, encoded_key}, {:ok, encoded_val}} -> "#{encoded_key}:#{encoded_val}"
      {{:ok, encoded_key}, _err} -> "#{encoded_key}:#{Jason.encode!(inspect(val))}"
    end
  end
end
