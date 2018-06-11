defmodule Castle.Plugs.Interval do
  import Plug.Conn

  @default_min "DAY"
  @default_skip_bucket false

  def init(opts) do
    opts
    |> Enum.into(%{})
    |> Map.put_new(:min, @default_min)
    |> Map.put_new(:skip_bucket, @default_skip_bucket)
  end

  def call(conn, opts) do
    conn
    |> assign(:interval, %{})
    |> interval_part(opts, :from, &Castle.Plugs.Interval.TimeFrom.parse/2)
    |> interval_part(opts, :to, &Castle.Plugs.Interval.TimeTo.parse/2)
    |> interval_part(opts, :bucket, &Castle.Plugs.Interval.Bucket.parse/2)
    |> round_time_window(opts)
    |> interval_struct()
  end

  defp interval_part(%{status: nil, assigns: %{interval: intv}} = conn, opts, key, valfn) do
    case valfn.(conn, opts) do
      {:ok, nil} ->
        conn
      {:ok, val} ->
        conn |> assign(:interval, Map.put(intv, key, val))
      {:error, err} ->
        conn |> send_resp(400, err) |> halt()
    end
  end
  defp interval_part(conn, _opts, _key, _valfn), do: conn

  defp round_time_window(conn, %{min: "HOUR"}), do: round_time_window(conn, Castle.Bucket.Hourly)
  defp round_time_window(conn, %{min: "DAY"}), do: round_time_window(conn, Castle.Bucket.Daily)
  defp round_time_window(%{status: nil, assigns: %{interval: intv}} = conn, round_to) do
    assign(conn, :interval, %{
      from: round_to.floor(intv.from),
      to: round_to.ceiling(intv.to),
      bucket: Map.get(intv, :bucket),
    })
  end
  defp round_time_window(conn, _round_to), do: conn

  defp interval_struct(%{status: nil, assigns: %{interval: intv}} = conn) do
    conn |> assign(:interval, struct!(Castle.Interval, intv))
  end
  defp interval_struct(conn), do: conn
end
