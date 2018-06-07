defmodule CastleWeb.Router do
  use CastleWeb, :router

  # pipeline :browser do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  # end

  pipeline :api do
    plug :accepts, ["json", "hal"]
  end
  pipeline :logged do
    plug Plug.Logger
  end

  pipeline :authorized do
    plug Castle.Plugs.Auth
  end

  pipeline :metrics do
    plug Castle.Plugs.Interval
    plug Castle.Plugs.Group
  end

  scope "/", CastleWeb do
    pipe_through :api

    get "/", RedirectController, :index
    get "/api", RedirectController, :index
    get "/api/v1", API.RootController, :index, as: :api_root
  end

  scope "/api/v1", CastleWeb.API, as: :api do
    pipe_through :api
    pipe_through :logged
    pipe_through :authorized

    resources "/podcasts", PodcastController, only: [:index, :show] do
      resources "/episodes", EpisodeController, only: [:index, :show]
    end
    resources "/episodes", EpisodeController, only: [:index, :show]

    scope "/podcasts", as: :podcast do
      pipe_through :metrics
      get "/:podcast_id/downloads", DownloadController, :index
    end

    scope "/episodes", as: :episode do
      pipe_through :metrics
      get "/:episode_guid/downloads", DownloadController, :index
    end
  end

end
