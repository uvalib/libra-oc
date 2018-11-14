FROM centos:7

# ruby dependancies
RUN yum -y update && yum -y install which tar wget make gcc-c++ zlib-devel libyaml-devel autoconf patch readline-devel libffi-devel openssl-devel bzip2 automake libtool bison sqlite-devel

# install ruby
RUN cd /tmp && wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.3.tar.gz
RUN cd /tmp && tar xzvf ruby-2.4.3.tar.gz
RUN cd /tmp/ruby-2.4.3 && ./configure && make && make install
RUN rm -fr /tmp/ruby-2.4.3 && rm /tmp/ruby-2.4.3.tar.gz

# install application dependancies
RUN yum -y install file git epel-release java-1.8.0-openjdk-devel ImageMagick mysql-devel #&&
RUN yum -y install clamav clamav-update clamav-devel
#&& yum -y install nodejs
# temp workaround until centos 7.4 (https://bugs.centos.org/view.php?id=13669&nbn=1)
RUN rpm -ivh https://kojipkgs.fedoraproject.org//packages/http-parser/2.7.1/3.el7/x86_64/http-parser-2.7.1-3.el7.x86_64.rpm && yum -y install nodejs

# install libreoffice
RUN cd /tmp && wget https://download.documentfoundation.org/libreoffice/stable/6.1.1/rpm/x86_64/LibreOffice_6.1.1_Linux_x86-64_rpm.tar.gz
RUN cd /tmp && tar xzfv LibreOffice_6.1.1_Linux_x86-64_rpm.tar.gz && cd /tmp/LibreOffice_6.1.1.2_Linux_x86-64_rpm/RPMS && yum -y localinstall *.rpm
RUN ln -s /opt/libreoffice5.4/program/soffice /usr/local/bin/soffice
RUN rm -fr /tmp/LibreOffice_6.1.1.2_Linux_x86-64_rpm && rm /tmp/LibreOffice_6.1.1_Linux_x86-64_rpm.tar.gz

# Create the run user and group
RUN groupadd -r --gid 18570 sse && useradd --uid 1984 -r -g sse docker && mkdir /home/docker

# set the timezone appropriatly
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# set the locale correctly
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

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

# copy the application
ADD . $APP_HOME

# Update permissions
RUN chown -R docker $APP_HOME /home/docker && chgrp -R sse $APP_HOME /home/docker

# freshen the antivirus definitions and update permissions so we can do this again
RUN freshclam && chmod -R o+w /var/lib/clamav

# generate the assets
RUN RAILS_ENV=production SECRET_KEY_BASE=x rake assets:precompile

# Specify the user
USER docker

# Define port and startup script
EXPOSE 3000
CMD scripts/entry.sh

# Move in other assets
COPY data/container_bash_profile /home/docker/.profile

#
# end of file
#
