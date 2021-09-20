defmodule CastleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :castle

  socket "/socket", CastleWeb.UserSocket,
    websocket: true,
    longpoll: true

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :castle,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_castle_key",
    signing_salt: "N6LvHZ+T"

  # CORS support
  plug Corsica,
    origins: ~r/.*\.prx\.(?:org|dev|tech|docker)$/,
    allow_headers: ~w(Authorization),
    allow_methods: ~w(HEAD GET),
    allow_credentials: true

  plug CastleWeb.Router
end
