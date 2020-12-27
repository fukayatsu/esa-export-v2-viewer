FROM ruby:2.7.2-alpine3.12

RUN apk add --no-cache \
  make g++

RUN mkdir /app
WORKDIR /app

ADD Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --retry=3
ADD . ./

EXPOSE 4567
CMD bundle exec ruby app.rb -o 0.0.0.0
