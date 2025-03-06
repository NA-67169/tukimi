FROM ruby:3.4.2 AS builder

RUN apt-get update -qq && \
    apt-get install -y nodejs npm && \
    npm install --global yarn

WORKDIR /api

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --without development test

COPY . .

RUN RAILS_ENV=production bundle exec rails assets:precompile

FROM ruby:3.4.2-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /api

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]