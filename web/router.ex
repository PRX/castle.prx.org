defmodule Porter.Router do
  use Porter.Web, :router

  # pipeline :browser do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  # end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :metrics do
    plug Porter.Plugs.TimeFrom
    plug Porter.Plugs.TimeTo
    plug Porter.Plugs.Interval
  end

  scope "/", Porter do
    pipe_through :api

    get "/", RedirectController, :index
    get "/api", RedirectController, :index
  end

  scope "/api/v1", Porter.API, as: :api do
    pipe_through :api

    get "/", RootController, :index
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
