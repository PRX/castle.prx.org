defmodule Castle.HttpCase do
  use ExUnit.CaseTemplate, async: false

  def resp("" <> body, code) do
    {:ok, %HTTPoison.Response{status_code: code, body: body}}
  end
  def resp(body, code) do
    {:ok, encoded_body} = Poison.encode(body)
    resp(encoded_body, code)
  end
  def resp(body), do: resp(body, 200)

  using do
    quote do
      import Mock

      defmacro with_http(body, do: expression) do
        quote do
          getter = fn(_url, _hdrs, _opts) ->
            unquote(body) |> Castle.HttpCase.resp()
          end
          with_mock HTTPoison, [get: getter] do
            unquote(expression)
          end
        end
      end

      defmacro with_http_fn(bodyfn, do: expression) do
        quote do
          getter = fn(_url, _hdrs, _opts) ->
            unquote(bodyfn).() |> Castle.HttpCase.resp()
          end
          with_mock HTTPoison, [get: getter] do
            unquote(expression)
          end
        end
      end
    end
  end
end
