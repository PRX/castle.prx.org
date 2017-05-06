FROM bitwalker/alpine-elixir:1.4.2

MAINTAINER PRX <sysadmin@prx.org>
LABEL org.prx.app="yes"

# install git, aws-cli
RUN apk --no-cache add git ca-certificates \
    python py-pip py-setuptools groff less && \
    pip --no-cache-dir install awscli

# install PRX aws-secrets scripts
RUN git clone -o github https://github.com/PRX/aws-secrets
RUN cp ./aws-secrets/bin/* /usr/local/bin

ADD mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

ADD . ./
RUN MIX_ENV=prod mix compile

# do this last, since it's not cached
ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
RUN chmod +x /tini

RUN chown -R default:nogroup $HOME
USER default

ENV MIX_ENV=prod
ENV RELX_REPLACE_OS_VARS=true
EXPOSE 4000

ENTRYPOINT [ "/tini", "--", "./bin/application" ]
CMD [ "web" ]
