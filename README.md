# clinic-booking

Appointment booking for clinics. A deliberately Heroku-shaped Rails application, used as the
source system in Qovery's "Heroku to AWS in one command" live migration webinar (24 September 2026).

Heroku-shaped means: Ruby buildpack, no Dockerfile, a `Procfile` with `web`, `worker` and
`release` process types, Heroku Postgres and Heroku Redis add-ons, Heroku Scheduler calling a rake
task, review apps through `app.json`, and about twenty-five config vars of which seven are secrets.

## Stack

- Rails 8.1, Puma, Propshaft, Hotwire
- Sidekiq on Redis for background jobs (confirmation emails, reminders)
- PostgreSQL 16

## Process types

| Type | Command | Heroku equivalent |
|------|---------|-------------------|
| web | `puma -C config/puma.rb` | web dyno |
| worker | `sidekiq -c $SIDEKIQ_CONCURRENCY` | worker dyno |
| release | `rails db:migrate` | release phase |
| scheduler | `rake reminders:enqueue` every 10 min | Heroku Scheduler add-on |

## Run locally the Heroku way

    bundle install
    bin/rails db:setup SEED_APPOINTMENTS=5000
    heroku local

## Endpoints

- `/` search practitioners, `/practitioners/:id` book
- `/api/practitioners?specialty=dentist&city=Paris` JSON
- `/up` health check
- `/sidekiq` job dashboard (basic auth from `SIDEKIQ_WEB_USER` / `SIDEKIQ_WEB_PASSWORD`)

## Config vars

See `app.json`. Secrets: `SECRET_KEY_BASE`, `DATABASE_URL`, `REDIS_URL`, `STRIPE_SECRET_KEY`,
`SENDGRID_API_KEY`, `TWILIO_AUTH_TOKEN`, `SIDEKIQ_WEB_PASSWORD`.

## Review apps

Every pull request gets its own Heroku review app with a seeded database (see `app.json`).
