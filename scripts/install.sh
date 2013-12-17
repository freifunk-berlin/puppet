aptitude install git
git clone https://github.com/freifunk/berlin-puppet.git
cd /tmp
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
cd ~
aptitude update
aptitude install puppet-common #standalone mode, no agent foo
aptitude install rubygems
gem install librarian-puppet --no-ri --no-rdoc
cd berlin-puppet/puppet
librarian-puppet install --verbose
puppet apply --verbose --modulepath=/root/berlin-puppet/puppet/modules \
  manifests/site.pp
cd ~
rm install.sh
