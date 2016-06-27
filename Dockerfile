FROM alpine:latest
MAINTAINER Jérémy Derussé "jeremy@derusse.com"

RUN apk --no-cache add \
    dnsmasq \
    openssl

ENV DOCKER_GEN_VERSION 0.5.0
ENV DOCKER_HOST unix:///var/run/docker.sock

RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
ADD config/dnsmasq.tmpl /etc/dnsmasq.tmpl
ADD dnsmasq-reload /usr/local/bin/dnsmasq-reload
ADD entrypoint /usr/local/bin/entrypoint

VOLUME /var/run
EXPOSE 53/udp

ENTRYPOINT ["entrypoint"]
