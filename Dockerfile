FROM ruby:2.3.3-alpine

RUN apk add --update --no-cache bash which tar file git openjdk8-jre imagemagick mysql-client mysql-dev \
    build-base libxml2-dev libxslt-dev tzdata\
    && apk add nodejs

# Create the run user and group
RUN addgroup webservice && adduser webservice -G webservice -D

# set the timezone appropriatly
ENV TZ=UTC
#ENV TZ=EST5EDT
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install bundler
RUN gem install bundler --no-ri --no-rdoc

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# create work directory
ENV APP_HOME /libra-oc
WORKDIR $APP_HOME

ADD . $APP_HOME

RUN rake assets:precompile

# Update permissions
RUN chown -R webservice $APP_HOME && chgrp -R webservice $APP_HOME

# Specify the user
USER webservice

# Define port and startup script
EXPOSE 3000
CMD scripts/entry.sh

# Move in other assets
COPY data/container_bash_profile /home/webservice/.profile
