defmodule Castle.HttpCase do
  use ExUnit.CaseTemplate, async: false

  def mock_http_resp({code, "" <> body}) do
    {:ok, %HTTPoison.Response{status_code: code, body: body}}
  end
  def mock_http_resp({code, body}) do
    {:ok, encoded_body} = Poison.encode(body)
    mock_http_resp({code, encoded_body})
  end
  def mock_http_resp(code) when is_integer(code), do: mock_http_resp({code, ""})
  def mock_http_resp(body), do: mock_http_resp({200, body})

  def mock_full_url(url, nil), do: url
  def mock_full_url(url, opts) do
    case opts[:params] do
      nil -> url
      params when map_size(params) == 0 -> url
      params -> "#{url}?#{URI.encode_query(params)}"
    end
  end

  defmacro test_with_http(name, mocks, do: expression) do
    quote do
      test unquote(name) do
        getter = fn(url, _hdrs, opts) ->
          full_url = mock_full_url(url, opts)
          case unquote(mocks)[full_url] do
            nil -> raise "Unmocked request for #{full_url}"
            val -> mock_http_resp(val)
          end
        end
        with_mock HTTPoison, [get: getter] do
          unquote(expression)
        end
      end
    end
  end

  using do
    quote do
      import Mock
      import Castle.HttpCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Castle.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Castle.Repo, {:shared, self()})
    end
    :ok
  end
end
