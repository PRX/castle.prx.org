defmodule CastleWeb.Paging do
  import Ecto.Query

  @default_per 10

  def parse_paging(params) do
    {
      Map.get(params, "page") |> parse_int(1),
      Map.get(params, "per") |> parse_int(@default_per)
    }
  end

  defp default_paging_params do
    %{
      page: nil,
      per: nil,
      total: nil,
      search: nil,
      last_page: nil
    }
  end

  def paging_links(base, paging) do
    %{total: total, per: per} = paging
    paging = default_paging_params()
             |> Map.merge(paging)
             |> Map.put(:last_page, (total / per) |> Float.ceil() |> trunc())

    %{}
      |> prev_link(base, paging)
      |> next_link(base, paging)
      |> first_link(base, paging)
      |> last_link(base, paging)
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

  defp prev_link(links, _, %{page: page}) when page == 1, do: links
  defp prev_link(links, base, %{page: page, per: per, search: search}) do
    Map.put links, :prev, %{href: make_link(base, page - 1, per, search)}
  end

  defp next_link(links, base, %{page: page, per: per, last_page: last_page, search: search}) do
    if last_page == page do
      links
    else
      Map.put links, :next, %{href: make_link(base, page + 1, per, search)}
    end
  end

  defp first_link(links, base, %{per: per, search: search}) do
    Map.put links, :first, %{href: make_link(base, 1, per, search)}
  end

  defp last_link(links, base, %{last_page: last_page, per: per, search: search}) do
    Map.put links, :last, %{href: make_link(base, last_page, per, search)}
  end

  defp add_search_param(link, search, has_params) when search == nil, do: link
  defp add_search_param(link, search, has_params) when has_params == true, do: "#{link}&search=#{search}"
  defp add_search_param(link, search, has_params) when has_params == false, do: "#{link}?search=#{search}"

  defp make_link(base, page, per, search) do
    link = case {page, per} do
      {1, @default_per} ->    add_search_param(base, search, false)
      {1, per} ->             add_search_param("#{base}?per=#{per}", search,  true)
      {prev, @default_per} -> add_search_param("#{base}?page=#{prev}", search,  true)
      {prev, per} ->          add_search_param("#{base}?page=#{prev}&per=#{per}", search,  true)
    end
  end
end
