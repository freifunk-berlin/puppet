node 'monitor' {

  package { ['tmux', 'htop', 'dstat', 'rrdtool', 'php5']:
    ensure => installed,
  }

  # install security updates
  class { 'apt::unattended_upgrades': }

  class { 'ntp': }

  # collectd configuration (server)
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class { 'collectd::plugin::network':
    listen => $ipaddress,
  }
  class { 'collectd::plugin::rrdtool': }

  # nginx configuration 
  class { 'nginx': }
  nginx::resource::vhost { 'monitor.berlin.freifunk.net':
    ensure      => present,
    www_root    => '/srv/www/monitor.berlin.freifunk.net',
    index_files => ['index.php'],
  }
  nginx::resource::location { 'php':
    ensure   => present,
    www_root => '/srv/www/monitor.berlin.freifunk.net',
    location => '~ [^/]\.php(/|$)',
    vhost    => 'monitor.berlin.freifunk.net',
    fastcgi  => 'unix:/var/run/php-fpm-monitor.berlin.freifunk.net.sock',

  }

  # php-fpm configuration (nginx backend)
  class { 'php-fpm': }
  php-fpm::pool { 'monitor.berlin.freifunk.net':
    listen  => '/var/run/php-fpm-monitor.berlin.freifunk.net.sock',
  }

  # root directory for monitor.berlin.freifunk.net
  file { ['/srv/www', '/srv/www/monitor.berlin.freifunk.net']:
    ensure  => directory,
    owner   => 'www-data',
    require => Class['nginx'],
  }

}
