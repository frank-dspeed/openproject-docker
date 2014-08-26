#!/bin/bash -e
pushd /tmp

## Brightbox Ruby 1.9.3, 2.0 and 2.1
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C3173AA6
echo deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu trusty main > /etc/apt/sources.list.d/brightbox.list
apt-get update && apt-get install -y ruby2.1 ruby2.1-dev
gem2.1 install rake bundler --no-rdoc --no-ri

## This script is to be run after ruby1.9.sh, ruby2.0.sh and ruby2.1.sh.

cp /build/ruby-switch /usr/local/bin/ruby-switch
echo "gem: --no-ri --no-rdoc" > /etc/gemrc

## Fix shebang lines in rake and bundler so that they're run with the currently
## configured default Ruby instead of the Ruby they're installed with.
sed -i 's|/usr/bin/env ruby.*$|/usr/bin/env ruby|; s|/usr/bin/ruby.*$|/usr/bin/env ruby|' \
	/usr/local/bin/rake /usr/local/bin/bundle /usr/local/bin/bundler

## The Rails asset compiler requires a Javascript runtime.
## Install development headers for native libraries that tend to be used often by Ruby gems.

## For nokogiri.
apt-get -y install libxml2-dev libxslt1-dev nodejs \
 imagemagick libmagickwand-dev libmysqlclient-dev libsqlite3-dev libpq-dev libqt4-webkit libqt4-dev \
 libcurl4-openssl-dev zlib1g-dev

## Set the latest available Ruby as the default.
if [[ -e /usr/bin/ruby2.1 ]]; then
	ruby-switch --set ruby2.1
elif [[ -e /usr/bin/ruby2.0 ]]; then
	ruby-switch --set ruby2.0
elif [[ -e /usr/bin/ruby1.9.1 ]]; then
	ruby-switch --set ruby1.9.1
fi


popd
