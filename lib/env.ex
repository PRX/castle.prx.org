defmodule Env do

  def get(key) do
    get_dot_env(key) || get_env_config(key)
  end

  defp get_dot_env(key) do
    key
    |> Atom.to_string
    |> String.upcase
    |> System.get_env
    |> fix_newlines
    |> fix_quotes
    |> defined_value
  end

  defp get_env_config(key) do
    Application.get_env(:castle, :env_config)[key]
    |> fix_newlines
    |> fix_quotes
    |> defined_value
  end

  # multiline .env values will have double encoded newlines
  defp fix_newlines("" <> val), do: String.replace(val, "\\n", "\n")
  defp fix_newlines(val), do: val

  # depending on environment (AWS ECS vs docker-compose) some things are quoted
  defp fix_quotes("\"" <> rest), do: String.replace(rest, ~r/"$/, "")
  defp fix_quotes(val), do: val

  # don't allow uncompiled "${KEY}" values
  def defined_value("${" <> _rest), do: nil
  def defined_value(""), do: nil
  def defined_value(val), do: val

end
