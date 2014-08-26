# From the Ubuntu Core Baseimage
FROM dockerimages/ubuntu-core:14.04

MAINTAINER Frank Lemanschik (Direkt SPEED), info@dspeed.eu

ENV MYSQL_PASSWORD=`pwgen -c -n -1 15`
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
deb mirror://mirrors.ubuntu.com/mirrors.txt trusty-security main restricted universe multiverse" > /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C3173AA6 \
 && echo deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main > /etc/apt/sources.list.d/brightbox.list
 && apt-get update -q && apt-get -y install apt-transport-https ca-certificates \
 && echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' > /etc/apt/sources.list.d/passenger.list \
 && apt-get update -q \
 && locale-gen en_US en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    curl git wget passanger libreadline-dev libgraphviz-dev libgvc6 memcached mysql-server \
    install libxml2-dev libxslt1-dev nodejs \
    imagemagick libmagickwand-dev libmysqlclient-dev libsqlite3-dev libpq-dev libqt4-webkit libqt4-dev \
    libcurl4-openssl-dev zlib1g-dev ruby2.1 ruby2.1-dev \
 && apt-get -y clean \
 && groupadd openproject \
 && useradd --create-home -g openproject -g sudo openproject \
 && BGHACK=$(/usr/bin/mysqld_safe &) \
 && sleep 7s \
 && mysqladmin -u root password $MYSQL_PASSWORD \
 && echo '#mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE openproject; GRANT ALL PRIVILEGES ON openproject.* TO "openproject"@"localhost" IDENTIFIED BY "$OPENPROJECT_DB_PASSWORD"; FLUSH PRIVILEGES;\"'

ADD ruby-switch /usr/local/bin
RUN chmod +x /usr/local/bin/ruby-switch \ 
 && gem2.1 install rake bundler --no-rdoc --no-ri \
 && echo "gem: --no-ri --no-rdoc" > /etc/gemrc \
 && sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
    /usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler \
 &&	ruby-switch --set ruby2.1

ADD ./files/Gemfile.local /home/openproject/openproject
ADD ./files/Gemfile.plugins /home/openproject/openproject
RUN ruby -v \
 && cd /home/openproject \
 && git clone --depth 1 https://github.com/opf/openproject.git \
 && cd openproject \
 && echo " \
production: \n\
  adapter: mysql2 \n\
  database: openproject \n\
  host: localhost \n\
  username: root \n\
  password: $MYSQL_PASSWORD \n\
  encoding: utf8 \n\
 \n\
development: \n\
  adapter: mysql2 \n\
  database: openproject \n\
  host: localhost \n\
  username: root \n\
  password: $MYSQL_PASSWORD \n\
  encoding: utf8 \n\
 \n\
test: \n\
  adapter: mysql2 \n\
  database: openproject_test \n\
  host: localhost \n\
  username: root \n\
  password: $MYSQL_PASSWORD \n\
  encoding: utf8" > /home/openproject/openproject/config/database.yml \
 && chown openproject /home/openproject 
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
