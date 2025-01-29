FROM ruby:3.3.6

WORKDIR /api

ENV RAILS_ENV=development
ENV BUNDLE_PATH=/usr/local/bundle
ENV PATH="/api/bin:${PATH}"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    postgresql-client \
    libpq-dev \
    build-essential \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN gem update --system && \
    gem install bundler

RUN bundle config set force_ruby_platform true && \
    bundle install

COPY . .

RUN chmod +x bin/rails

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD ["bin/rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
