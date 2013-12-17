node 'monitor' {
  class { 'ntp': }
  class { 'nginx': }
  nginx::resource::vhost { 'monitor.berlin.freifunk.net':
    ensure => present,
    www_root => '/srv/www/monitor.berlin.freifunk.net',
  }
}
