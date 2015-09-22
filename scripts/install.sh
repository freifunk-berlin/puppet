aptitude install git
git clone https://github.com/freifunk/berlin-puppet.git
cd /tmp
wget http://apt.puppetlabs.com/puppetlabs-release-$(lsb_release -cs).deb
dpkg -i puppetlabs-release-$(lsb_release -cs).deb
cd ~
aptitude update
aptitude install puppet-common #standalone mode, no agent foo
aptitude install rubygems
aptitude install build-essential ruby-dev
gem install librarian-puppet --no-ri --no-rdoc -V
cd berlin-puppet/puppet
librarian-puppet install --verbose
puppet apply --verbose --modulepath=/root/berlin-puppet/puppet/modules \
  manifests/site.pp
cd ~
rm install.sh
