aptitude install git
git clone https://github.com/freifunk/berlin-puppet.git
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
aptitude update
aptitude install puppet-common #standalone mode, no agent foo
