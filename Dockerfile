# Built for Qovery during the Heroku migration (replaces the heroku/ruby buildpack).
# Same image runs web (default CMD), worker, db-migrate, db-seed and the reminders cron.
FROM ruby:3.3-slim AS builder
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential libpq-dev git libyaml-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV RAILS_ENV=production BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT="development:test" BUNDLE_PATH=/usr/local/bundle
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf "${BUNDLE_PATH}"/ruby/*/cache
COPY . .
RUN bundle exec bootsnap precompile app/ lib/ \
    && SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM ruby:3.3-slim
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq5 curl \
    && rm -rf /var/lib/apt/lists/*
ENV RAILS_ENV=production BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT="development:test" BUNDLE_PATH=/usr/local/bundle \
    RAILS_LOG_TO_STDOUT=enabled RAILS_SERVE_STATIC_FILES=enabled PORT=3000
RUN groupadd --system --gid 1000 rails && useradd --system --uid 1000 --gid 1000 --create-home rails
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app
USER 1000:1000
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
