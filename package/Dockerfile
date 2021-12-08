FROM centos:7

# ruby dependancies
RUN yum -y update && yum -y install which tar wget make gcc-c++ zlib-devel libyaml-devel autoconf patch readline-devel libffi-devel openssl-devel bzip2 automake libtool bison sqlite-devel

# install ruby
RUN cd /tmp && wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.3.tar.gz
RUN cd /tmp && tar xzvf ruby-2.4.3.tar.gz
RUN cd /tmp/ruby-2.4.3 && ./configure && make && make install
RUN rm -fr /tmp/ruby-2.4.3 && rm /tmp/ruby-2.4.3.tar.gz

# install application dependancies
RUN yum -y install file git epel-release java-1.8.0-openjdk-devel ImageMagick mysql-devel
RUN yum -y install clamav clamav-update clamd
RUN yum -y install nodejs

# install libreoffice
RUN cd /tmp && wget https://download.documentfoundation.org/libreoffice/stable/7.2.4/rpm/x86_64/LibreOffice_7.2.4_Linux_x86-64_rpm.tar.gz
RUN cd /tmp && tar xzfv LibreOffice_7.2.4_Linux_x86-64_rpm.tar.gz && cd /tmp/LibreOffice_7.2.4.1_Linux_x86-64_rpm/RPMS && yum -y localinstall *.rpm
RUN ln -s /opt/libreoffice7.1/program/soffice /usr/local/bin/soffice
RUN rm -fr /tmp/LibreOffice_7.2.4.1_Linux_x86-64_rpm && rm /tmp/LibreOffice_7.2.4_Linux_x86-64_rpm.tar.gz

# Create the run user and group
RUN groupadd -r --gid 18570 sse && useradd --uid 1984 -r -g sse docker && mkdir /home/docker

# set the timezone appropriatly
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# set the locale correctly
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# install bundler
RUN gem install bundler -v 2.2.20 --no-document

# create work directory
ENV APP_HOME /libra-oc
WORKDIR $APP_HOME

# Copy the Gemfile and Gemfile.lock into the image.
ADD Gemfile Gemfile.lock ./
RUN bundle install --jobs=4 --without=["development" "test"] --no-cache

# copy the application
ADD . $APP_HOME

# Update permissions
RUN chown -R docker $APP_HOME /home/docker && chgrp -R sse $APP_HOME /home/docker

# freshen the antivirus definitions and update permissions so we can do this again
RUN sed -i 's/Example/#Example/' /etc/freshclam.conf
RUN freshclam && chmod -R o+rw /var/lib/clamav /etc/freshclam.conf

# generate the assets
RUN RAILS_ENV=production SECRET_KEY_BASE=x rake assets:precompile

# Define port and startup script
EXPOSE 8080
CMD scripts/entry.sh

# Move in other assets
COPY data/container_bash_profile /home/docker/.profile

# Ensure permissions are correct
RUN chown docker:sse /home/docker/.profile $APP_HOME/scripts/entry.sh && chmod 755 /home/docker/.profile $APP_HOME/scripts/entry.sh

# Add the build tag
ARG BUILD_TAG
RUN test -n "$BUILD_TAG" && touch $APP_HOME/buildtag.build-$BUILD_TAG || touch $APP_HOME/buildtag.build-0

# Specify the user
USER docker

#
# end of file
#
