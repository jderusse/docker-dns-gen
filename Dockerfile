FROM alpine:latest
MAINTAINER Jérémy Derussé "jeremy@derusse.com"

RUN apk --no-cache add \
    dnsmasq \
    openssl

ENV DOCKER_GEN_VERSION 0.7.3
ENV DOCKER_HOST unix:///var/run/docker.sock

RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
ADD config/dnsmasq.tmpl /etc/dnsmasq.tmpl
ADD config/service/dnsmasq /etc/governator/services/dnsmasq
ADD config/service/dnsmasq-reload /etc/governator/services/dnsmasq-reload
ADD dnsmasq-reload /usr/local/bin/dnsmasq-reload
ADD bin/governator /usr/local/bin/governator

VOLUME /var/run
EXPOSE 53/udp

CMD ["governator", "-D"]
