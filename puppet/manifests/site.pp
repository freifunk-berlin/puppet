node 'monitor' {

  package { ['tmux', 'htop', 'dstat', 'rrdtool', 'php5']:
    ensure => installed,
  }

  # sysctl configuration
  # disable ipv6 auto-configuration
  sysctl { 'net.ipv6.conf.all.autoconf': value => '0' }
  sysctl { 'net.ipv6.conf.all.accept_ra': value => '0' }
  sysctl { 'net.ipv6.conf.all.use_tempaddr': value => '0' }

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
  class { 'collectd::plugin::rrdcached':
    daemonaddress => 'unix:/var/run/rrdcached.sock',
    datadir       => '/var/lib/collectd/rrd',
  }

  # rrdcached configuration
  class { 'rrdcached':
    restrict_writes => true,
    jump_dir        => '/var/lib/collectd/rrd',
    timeout         => 600,
    delay           => 60,
  }

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
  file { ['/srv/www']:
    ensure  => directory,
    owner   => 'www-data',
    require => Class['nginx'],
  }

  # Collectd Graph Panel (patched by Patrick) https://github.com/stargieg/CGP.git
  vcsrepo { '/srv/www/monitor.berlin.freifunk.net':
    ensure   => latest,
    provider => git,
    owner    => 'www-data',
    source   => 'https://github.com/stargieg/CGP.git',
    require  => File['/srv/www']
  }
}
