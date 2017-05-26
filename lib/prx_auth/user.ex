defmodule PrxAuth.User do

  defstruct id: nil, auths: %{}

  def unpack(claims \\ %{}) do
    claims = claims
      |> Map.put_new("sub", nil)
      |> Map.put_new("aur", %{})
      |> Map.put_new("scope", "")

    # first, gather all resource ids (under aur[id] or aur[$][scope][id])
    normal_ids = claims["aur"]
      |> Map.delete("$")
      |> Map.delete("")
      |> Map.keys()
    dollar_ids = (Map.get(claims["aur"], "$") || %{})
      |> Map.values()
      |> Enum.map(&listify_strings/1)
      |> Enum.concat()
    ids = Enum.concat(normal_ids, dollar_ids)
      |> Enum.map(&stringify_numbers/1)
      |> Enum.uniq()

    # now map ids to their scopes
    auths = ids
      |> Enum.map(&global_scopes(&1, claims["scope"]))
      |> Enum.map(&aur_scopes(&1, claims["aur"]))
      |> Enum.map(&dollar_scopes(&1, Map.get(claims["aur"], "$")))
      |> Enum.map(&mapify_scopes/1)
      |> Enum.into(%{})

    %PrxAuth.User{id: claims["sub"], auths: auths}
  end

  defp listify_strings("" <> scopes), do: String.split(scopes)
  defp listify_strings(scopes), do: scopes

  defp stringify_numbers(num) when is_integer(num), do: Integer.to_string(num)
  defp stringify_numbers(str), do: str

  defp mapify_scopes({id, scopes}) do
    {
      id,
      scopes |> Enum.map(fn(s) -> {s, true} end) |> Enum.into(%{})
    }
  end

  defp global_scopes(id, ""), do: {id, []}
  defp global_scopes(id, scopes), do: {id, listify_strings(scopes)}

  defp aur_scopes({id, scopes}, aur) do
    aur_scopes = Map.to_list(aur)
      |> Enum.map(fn({id, scopes}) -> {stringify_numbers(id), scopes} end)
      |> Enum.into(%{})
      |> Map.get(id)
    {id, scopes ++ listify_strings(aur_scopes || [])}
  end

  defp dollar_scopes(auth, nil), do: auth
  defp dollar_scopes({id, scopes}, dollar) do
    xtra_scopes = dollar |> Map.keys |> Enum.filter(&in_scope(dollar[&1], id))
    {id, scopes ++ xtra_scopes}
  end

  defp in_scope(ids, id) do
    listify_strings(ids) |> Enum.map(&stringify_numbers/1) |> Enum.member?(stringify_numbers(id))
  end
end
