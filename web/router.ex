defmodule Castle.Router do
  use Castle.Web, :router

  # pipeline :browser do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  # end

  pipeline :api do
    plug :accepts, ["json", :hal]
  end

  pipeline :authorized do
    plug Castle.Plugs.BasicAuth
  end

  pipeline :metrics do
    plug Castle.Plugs.TimeFrom
    plug Castle.Plugs.TimeTo
    plug Castle.Plugs.Interval
  end

  scope "/", Castle do
    pipe_through :api

    get "/", RedirectController, :index
    get "/api", RedirectController, :index
    get "/api/v1", API.RootController, :index, as: :api_root
  end

  scope "/api/v1", Castle.API, as: :api do
    pipe_through :api
    pipe_through :authorized

    resources "/podcasts", PodcastController, only: [:index, :show]
    resources "/episodes", EpisodeController, only: [:index, :show]

    scope "/podcasts", as: :podcast do
      pipe_through :metrics
      get "/:podcast_id/downloads", DownloadController, :index
      get "/:podcast_id/impressions", ImpressionController, :index
    end

    scope "/episodes", as: :episode do
      pipe_through :metrics
      get "/:episode_guid/downloads", DownloadController, :index
      get "/:episode_guid/impressions", ImpressionController, :index
    end
  end

end
