# Porter.prx.org

## Description

[Phoenix app](http://www.phoenixframework.org) providing an API to PRX metrics in BigQuery.

This project follows the [standards for PRX services](https://github.com/PRX/meta.prx.org/wiki/Project-Standards#services).

## Installation

### Local

To get started, make sure you have completed the [Phoenix install guide](http://www.phoenixframework.org/docs/installation).  Then:

```
# Get the code
git clone git@github.com:PRX/porter.prx.org.git

# Install dependencies
mix deps.get

# Configure your environment (you'll need a bigquery table and service account)
cp env-example .env
vi .env
```

### Docker

TODO: Docker support.

## Dependencies

TODO: probably feeder?  Bigquery?

## Usage

```
# Start the phoenix server
mix phoenix.server

# Or run interactively
iex -S mix phoenix.server

# Or just get a console
iex -S mix
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

## License

[AGPL License](https://www.gnu.org/licenses/agpl-3.0.html)

## Contributing

Completing a Contributor License Agreement (CLA) is required for PRs to be accepted.
