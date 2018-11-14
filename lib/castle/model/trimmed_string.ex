defmodule Castle.Model.TrimmedString do
  @behaviour Ecto.Type
  def type, do: :trimmed_string

  def cast("" <> str), do: {:ok, String.trim(str)}
  # def cast(nil), do: {:ok, nil}
  def cast(_), do: :error

  def load("" <> str), do: {:ok, String.trim(str)}
  # def load(nil), do: {:ok, nil}
  def load(_), do: :error

  def dump("" <> str), do: {:ok, String.trim(str)}
  # def dump(nil), do: {:ok, nil}
  def dump(_), do: :error
end
