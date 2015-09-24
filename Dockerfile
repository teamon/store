FROM ruby:2.2.3-slim

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install --deployment

COPY . /usr/src/app

CMD bin/rackup -p $PORT
