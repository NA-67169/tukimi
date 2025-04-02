FROM ruby:3.4.2

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm && \
    npm install -g yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gem install rails -v 7.2.2.1
