node 'monitor' {
  package { ['tmux', 'htop', 'dstat']:
    ensure => installed,
  }
  class { 'ntp': }
  class { 'nginx': }
  nginx::resource::vhost { 'monitor.berlin.freifunk.net':
    ensure      => present,
    www_root    => '/srv/www/monitor.berlin.freifunk.net',
    index_files => ['index.php'],
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class { 'collectd::plugin::network':
    listen => $ipaddress,
  }
  class { 'php-fpm': }
  php-fpm::pool { 'monitor.berlin.freifunk.net':
    listen  => '/var/run/php-fpm-monitor.berlin.freifunk.net.sock',
    require => Class['php-fpm'], #TODO this should be done by the module
  }
}
