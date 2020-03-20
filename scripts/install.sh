#!/usr/bin/env bash
apt-get update
apt-get -y install puppet-common rubygems  build-essential ruby-dev git
git clone https://github.com/freifunk/berlin-puppet.git
gem install librarian-puppet --no-ri --no-rdoc -V
cd berlin-puppet/puppet
librarian-puppet install --verbose
puppet apply --verbose --modulepath=/root/berlin-puppet/puppet/modules \
  manifests/site.pp
cd ~
rm install.sh
