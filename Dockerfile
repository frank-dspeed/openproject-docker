# From the Ubuntu Core Baseimage
FROM dockerimages/ubuntu-core:14.04

MAINTAINER Frank Lemanschik (Direkt SPEED), info@dspeed.eu

ENV MYSQL_PASSWORD "random"
ENV RBENV_ROOT /home/openproject/.rbenv
ENV PATH /home/openproject/.rbenv/bin:$PATH
ENV CONFIGURE_OPTS --disable-install-doc
ENV HOME /home/openproject
EXPOSE 80

# Install ruby and its dependencies
# Install Passanger (Ruby App Server)
# Install MySql Server
# Install Python 
# Install APT-SSH Transporter.
#
RUN echo "deb mirror://mirrors.ubuntu.com/mirrors.txt trusty main restricted universe multiverse \n\
    deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-updates main restricted universe multiverse \n\
    deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-backports main restricted universe multiverse \n\
    deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" > /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C3173AA6 \
 && echo deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main > /etc/apt/sources.list.d/brightbox.list \
 && apt-get update -q && apt-get -y install apt-transport-https ca-certificates \
 && echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' > /etc/apt/sources.list.d/passenger.list \
 && apt-get update -q \
 && locale-gen en_US en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    curl git wget passenger libreadline-dev libgraphviz-dev libgvc6 memcached mysql-server \
    libxml2-dev libxslt1-dev nodejs imagemagick libmagickwand-dev libmysqlclient-dev libsqlite3-dev \
    libpq-dev libqt4-webkit libqt4-dev libcurl4-openssl-dev zlib1g-dev ruby2.1 ruby2.1-dev \
 && apt-get -y clean \
 && groupadd openproject \
 && useradd --create-home -g openproject -g sudo openproject \
 && mysqladmin -u root password $MYSQL_PASSWORD \
 && ps aux | grep mysql 
RUN echo '#mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE openproject; GRANT ALL PRIVILEGES ON openproject.* TO "openproject"@"localhost" IDENTIFIED BY "$OPENPROJECT_DB_PASSWORD"; FLUSH PRIVILEGES;"' \
 && cd /home/openproject \
 && ls -ao
 && git clone https://github.com/opf/openproject \
 && echo "# run server with unicorn \n\
    \n\
    gem 'passenger'" > /home/openproject/openproject Gemfile.local \
 && echo "# take the latest and greatest openproject gems from their unstable git branches \n\
    # this way we are up-to-date but might experience some bugs \n\
    \n\
    gem 'openproject-plugins',    :git => 'https://github.com/opf/openproject-plugins.git',         :branch => 'dev' \n\
    gem 'openproject-backlogs',   :git => 'https://github.com/finnlabs/openproject-backlogs.git',   :branch => 'dev' \n\
    gem 'openproject-pdf_export', :git => 'https://github.com/finnlabs/openproject-pdf_export.git', :branch => 'dev' \n\
    gem 'openproject-meeting',    :git => 'https://github.com/finnlabs/openproject-meeting.git',    :branch => 'dev' \n\
    gem 'openproject-costs',      :git => 'https://github.com/finnlabs/openproject-costs.git',      :branch => 'dev' "> /home/openproject/openproject/Gemfile.plugins \
 && echo "production: \n\
  adapter: mysql2 \n\
  database: openproject \n\
  host: localhost \n\
  username: root \n\
  password: $MYSQL_PASSWORD \n\
  encoding: utf8 \n\n" > /home/openproject/openproject/config/database.yml \project.git \
 && cd openproject \
 && gem2.1 install rake bundler --no-rdoc --no-ri \
 && echo "gem: --no-ri --no-rdoc" > /etc/gemrc \
 && sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
    /usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler \
 && chown openproject /home/openproject \
 && bundle install \
 && bundle exec rake db:create:all \
 && bundle exec rake db:migrate \
 && bundle exec rake generate_secret_token \
 && RAILS_ENV=production bundle exec rake db:seed \
 && bundle exec rake assets:precompile \
 && bundle exec passenger start --runtime-check-only \
 && killall mysqld \
 && sleep 7s \
 && chown -R openproject /home/openproject \
 && easy_install supervisor \
 && mkdir /var/log/supervisor/

ADD ./files/passenger-standalone.json /home/openproject/openproject/passenger-standalone.json
ADD ./files/start_openproject.sh /home/openproject/start_openproject.sh
ADD ./files/start_openproject_worker.sh /home/openproject/start_openproject_worker.sh
ADD ./files/supervisord.conf /etc/supervisord.conf
CMD ["supervisord", "-n"]
