FROM ruby:3.4.3-slim AS base

RUN apt update && \
    apt install -y --no-install-recommends \
    build-essential \
    libyaml-dev \
    git \
    curl

WORKDIR /workspace

COPY . .

FROM base AS builder

RUN bundle install