#-- copyright
# OpenProject-docker is a set-up script for OpenProject using the
# 'Apache 2.0' licensed docker container engine. See
# http://docker.io and https://github.com/dotcloud/docker for details
#
# OpenProject is a project management system.
# Copyright (C) 2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT.md for more details.
#++

# From the Ubuntu Core Baseimage
FROM dockerimages/ubuntu-core:14.04
MAINTAINER Frank Lemanschik (Direkt SPEED), info@dspeed.eu
# expose rails server port
EXPOSE 80
# Install ruby and its dependencies
# Install Passanger (Ruby App Server)
# Install MySql Server
# Install Python 
# Install APT-SSH Transporter.
#
# RUN echo "deb http://archive.ubuntu.com/ubuntu saucy main universe" > /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 \
 && echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main' > /etc/apt/sources.list.d/passenger.list \
 && apt-get update -q \
 && locale-gen en_US en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    build-essential curl git zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev \
    libxslt-dev libxslt1-dev libmysqlclient-dev libpq-dev libsqlite3-dev libyaml-0-2 libmagickwand-dev \
    libmagickcore-dev libmagickcore5-extra libgraphviz-dev libgvc5 ruby-dev apt-transport-https ca-certificates \
    memcached subversion vim wget python-setuptools openssh-server sudo pwgen libcurl4-openssl-dev passenger \
    mysql-client mysql-server \
 && apt-get -y clean
#RUN chown root: /etc/apt/sources.list.d/passenger.list
#RUN chmod 600 /etc/apt/sources.list.d/passenger.list

#
# Setup OpenProject
#
ENV CONFIGURE_OPTS --disable-install-doc
ENV PATH /home/openproject/.rbenv/bin:$PATH
ADD ./files/Gemfile.local /Gemfile.local
ADD ./files/Gemfile.plugins /Gemfile.plugins
ADD ./files/setup_system.sh /setup_system.sh
RUN /bin/bash /setup_system.sh
RUN rm /setup_system.sh

ADD ./files/passenger-standalone.json /home/openproject/openproject/passenger-standalone.json
ADD ./files/start_openproject.sh /home/openproject/start_openproject.sh
ADD ./files/start_openproject_worker.sh /home/openproject/start_openproject_worker.sh

#
# Add, Init Part launch supervisord in foreground mode.
#
RUN easy_install supervisor
RUN mkdir /var/log/supervisor/
ADD ./files/supervisord.conf /etc/supervisord.conf
#ENTRYPOINT ["supervisord", "-n"]
CMD ["supervisord", "-n"]
# RUN echo "INFO: openproject ssh password: `cat /root/openproject-root-pw.txt`"
