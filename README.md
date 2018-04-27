# Castle.prx.org

## Description

[Phoenix app](http://www.phoenixframework.org) providing an API to PRX metrics in BigQuery.

This project follows the [standards for PRX services](https://github.com/PRX/meta.prx.org/wiki/Project-Standards#services).

## Installation

### Local

To get started, make sure you have completed the [Phoenix install guide](http://www.phoenixframework.org/docs/installation).  Then:

```
# Get the code
git clone git@github.com:PRX/castle.prx.org.git

# Install dependencies
mix deps.get

# Configure your environment (you'll need a bigquery table and service account)
cp env-example .env
vi .env
```

### Docker

Currently on OSX, [Dinghy](https://github.com/codekitchen/dinghy) is probably
the best way to set up your dev environment.  Using VirtualBox is recommended.
Also be sure to install `docker-compose` along with the toolbox.

This project is setup primarily to build a `MIX_ENV=prod` docker image. To avoid
recompiling dependencies every time you run a non-prod docker-compose command,
mount some local directories to mask the build/deps directories in the image.

```
docker-compose build

# mount dev dependencies locally
mkdir _build_docker_compose deps_docker_compose
docker-compose run castle compile

# now you can run a local server
docker-compose up
open http://castle.prx.docker

# or run the tests
docker-compose run castle test
docker-compose run castle test --include external

# or run a single test
docker-compose run castle test test/controllers/api/root_controller_test.exs
```

## Dependencies

BigQuery, Redis, and Postgres.  But if you use docker-compose, you'll only need
to configure BigQuery.

## Usage

```
# Start the phoenix server
mix phx.server

# Or run interactively
iex -S mix phx.server

# Or just get a console
iex -S mix
```

## Tasks

### Feeder Sync

Sync all podcasts/episodes from `FEEDER_HOST` into your local Postgres database.
By default, will only go through a few pages of results at a time, before
returning.  Use `--all` to process all pages (which might take a long time for
all episodes in Feeder).  Similarly, the `--force` flag will sync all
podcasts/episodes since the beginning of time, and can take a long time.

The scheduler uses `--lock` to ensure 2 servers aren't attempting to sync the
same data at the same time.  The schedule is set in `config/prod.exs`, and
disabled in other environments by default.

```
mix feeder.sync [--lock,--all,--force]
```

### Rollup

*DEPRECATED* These bigquery rollups are deprecated, and will soon be replaced
with cron-like scheduled postgres rollups.  For now, these run automatically in
prod via the intervals in `config/prod.exs`.

```
mix castle.rollup
```

## Testing

```
# Run all the tests
mix test

# Run a specific test
mix test test/big_query/base/http_test.exs

# Include external dependency tests (requires a valid .env)
mix test --include external
```

## Scripts

The `/scripts/` directory contains some useful utilities for load/reloading
3rd party data (Geolite, User-Agents, etc).  These are not intended to be run
often, so buyer beware.  You will need to install some global ruby gems to get
the scripts to work, but that's all manual at this point.

You'll also need to [set up a Google API key](https://support.google.com/googleapi/answer/6158862).
Create a Service Account key with write access to the project/tables you want to
alter, and save it to `/scripts/.credentials.json`.

## License

[AGPL License](https://www.gnu.org/licenses/agpl-3.0.html)

## Contributing

Completing a Contributor License Agreement (CLA) is required for PRs to be accepted.
