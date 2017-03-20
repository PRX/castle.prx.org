defmodule Env do

  def get(key) do
    get_dot_env(key) || get_env_config(key)
  end

  defp get_dot_env(key) do
    key
    |> Atom.to_string
    |> String.upcase
    |> System.get_env
    |> String.replace("\\n", "\n")
  end

  defp get_env_config(key) do
    Application.get_env(:porter, :env_config)[key] |> defined_value
  end

  # don't allow uncompiled "${KEY}" values
  defp defined_value("${" <> _rest), do: nil
  defp defined_value(val), do: val

end
