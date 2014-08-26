#!/bin/bash -e
pushd /tmp

git clone git://github.com/sstephenson/rbenv.git /home/ubuntu/.rbenv              && \
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build

export PATH=$PATH:/home/ubuntu/.rbenv/bin
export RBENV_VERSION=2.1.0
eval "$(rbenv init -)"
CC=gcc rbenv install 2.1.0
rbenv rehash
rbenv global 2.1.0
rbenv rehash
gem install bundler
rbenv rehash

popd
