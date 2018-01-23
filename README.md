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

Currently, just BigQuery. Oh, and Redis. You should be running a `redis-server`
if you're trying to develop/test locally and not in Docker.

## Usage

```
# Start the phoenix server
mix phx.server

# Or run interactively
iex -S mix phx.server

# Or just get a console
iex -S mix
```

## Rollups

Certain queries can be expensive to run against BigQuery, so we cache these to
Redis in a background worker.  The interval at which the worker runs in prod is
configured in `config/prod.exs`.  But in dev/test, these queries will never run
by default.

To manually get rollups in your development Redis, just run `mix castle.rollup`.

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
