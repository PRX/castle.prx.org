defmodule CastleWeb.Paging do
  import Ecto.Query

  @default_per 10

  def parse_paging(params) do
    {
      Map.get(params, "page") |> parse_int(1),
      Map.get(params, "per") |> parse_int(@default_per)
    }
  end

  def paging_links(base, %{page: page, per: per, total: total}) do
    last_page = (total / per) |> Float.ceil() |> trunc()
    %{}
      |> prev_link(base, page, per)
      |> next_link(base, page, last_page, per)
      |> first_link(base, per)
      |> last_link(base, last_page, per)
  end

  def paginated_results(queryable, per, page) do
    offset = (page - 1) * per
    queryable
    |> offset(^offset)
    |> limit(^per)
    |> Castle.Repo.all
  end

  defp parse_int(num, _) when is_integer(num) and num > 0, do: num
  defp parse_int("" <> str, default_val), do: String.to_integer(str) |> parse_int(default_val)
  defp parse_int(_, default_val), do: default_val

  defp prev_link(links, _, 1, _), do: links
  defp prev_link(links, base, page, per) do
    Map.put links, :prev, %{href: make_link(base, page - 1, per)}
  end

  defp next_link(links, _, page, last_page, _) when page == last_page, do: links
  defp next_link(links, base, page, _, per) do
    Map.put links, :next, %{href: make_link(base, page + 1, per)}
  end

  defp first_link(links, base, per) do
    Map.put links, :first, %{href: make_link(base, 1, per)}
  end

  defp last_link(links, base, last_page, per) do
    Map.put links, :last, %{href: make_link(base, last_page, per)}
  end

  defp make_link(base, page, per) do
    case {page, per} do
      {1, @default_per} -> base
      {1, per} -> "#{base}?per=#{per}"
      {prev, @default_per} -> "#{base}?page=#{prev}"
      {prev, per} -> "#{base}?page=#{prev}&per=#{per}"
    end
  end
end
