FROM elixir:1.12.3-alpine AS builder

WORKDIR /opt/app
ENTRYPOINT [ "./bin/application" ]

RUN apk add --no-cache bash build-base inotify-tools git python3 py3-pip
RUN git clone https://github.com/PRX/aws-secrets /opt/aws-secrets
RUN mix local.rebar --force && mix local.hex --force

ADD mix.exs mix.lock ./
RUN MIX_ENV=dev mix do deps.get, deps.compile
RUN grep 'version:' mix.exs | cut -d '"' -f2 > .version

ADD . ./

RUN mkdir -p /opt/built && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix deps.get && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix compile && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix distillery.release && \
    cp _build/prod/rel/castle/releases/$(cat .version)/castle.tar.gz /opt/built && \
    cd /opt/built && \
    tar -xzf castle.tar.gz && \
    rm castle.tar.gz

# NOTE: alpine version here must match the above elixir image
# you can find with "grep VERSION_ID /etc/os-release | cut -d "=" -f2"
FROM alpine:3.16.0 AS built
LABEL maintainer="PRX <sysadmin@prx.org>"
LABEL org.prx.app="yes"
LABEL org.prx.spire.publish.ecr="ELIXIR_APP"
RUN apk add --no-cache bash openssl-dev python3 py3-pip && ln -s /usr/bin/python3 /usr/bin/python
RUN pip3 --disable-pip-version-check --no-cache-dir install awscli
ENV MIX_ENV=prod
ENV USE_BUILT=true
WORKDIR /opt/app
COPY --from=builder /opt/built .
COPY --from=builder /opt/app/bin/* bin/
COPY --from=builder /opt/aws-secrets/bin/aws-secrets-get* /usr/local/bin/
ENTRYPOINT [ "./bin/application" ]
CMD web
