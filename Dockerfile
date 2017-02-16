FROM ruby:2.3.3-alpine

RUN apk add --update --no-cache bash which tar file git openjdk8-jre imagemagick mysql-client mysql-dev \
    build-base libxml2-dev libxslt-dev tzdata\
    && apk add nodejs

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#ENV RAILS_ENV=production
RUN gem install bundler --no-ri --no-rdoc

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ADD vendor/gems vendor/gems
RUN bundle install

# create work directory
ENV APP_HOME /libra2-oc
WORKDIR $APP_HOME

ADD . $APP_HOME

RUN rake assets:precompile

# Define port and startup script
EXPOSE 3000
CMD scripts/entry.sh
