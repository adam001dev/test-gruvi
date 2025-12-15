FROM ruby:3.4.7-slim

ENV RAILS_ENV=development \
  BUNDLE_PATH=/usr/local/bundle \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

RUN apt-get update -qq && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  libyaml-dev \
  pkg-config \
  nodejs \
  npm \
  git \
  curl && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bash", "-lc", "bundle exec rails db:prepare && bundle exec rails s -b 0.0.0.0 -p 3000"]

