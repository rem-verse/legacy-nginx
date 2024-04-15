FROM ubuntu:jammy
LABEL maintainer="Cynthia <cynthia@corp.rem-verse.email>"

RUN apt-get update \
  && apt-get install -y software-properties-common wget \
  && wget -qO - https://legacy-nginx.apt.rem-verse.com/packaging.asc > /etc/apt/trusted.gpg.d/legacy-nginx.asc \
  && add-apt-repository "deb https://legacy-nginx.apt.rem-verse.com/ production main" \
  && apt-get update \
  && apt-get install -y legacy-nginx \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
