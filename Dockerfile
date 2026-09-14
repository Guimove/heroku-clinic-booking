# Build image for Qovery. Replaces the heroku/ruby buildpack: same app, explicit steps.
FROM ruby:3.3.12-slim-bookworm AS builder
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true \
 && bundle config set --local without 'development test' \
 && bundle install --jobs 4 --retry 3
COPY . .
# Rails 8 lets assets:precompile run without a real secret.
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bundle exec rails assets:precompile

FROM ruby:3.3.12-slim-bookworm
# libvips42: Bundler.require loads image_processing in production.
# tzdata: config.time_zone reads DEFAULT_TIMEZONE (Europe/Paris).
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      libpq5 libvips42 tzdata \
    && rm -rf /var/lib/apt/lists/*
RUN groupadd -r app && useradd -r -g app -d /app app
WORKDIR /app
COPY --from=builder --chown=app:app /app /app
RUN mkdir -p tmp/pids log storage && chown -R app:app tmp log storage
USER app
ENV RAILS_ENV=production BUNDLE_DEPLOYMENT=true BUNDLE_WITHOUT='development test'
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
