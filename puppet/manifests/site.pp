node 'base_node' {

  # update packages before we install any
  exec { "apt-update":
    command => "/usr/bin/apt-get update"
  }
  Exec["apt-update"] -> Package <| |>

  # do not install recommended packages
  Package {
    install_options => ['--no-install-recommends'],
  }

  package { ['tmux', 'htop', 'dstat', 'git']:
    ensure => installed,
  }

  # install security updates
  class { 'apt::unattended_upgrades': }

  class { 'ntp': }

  # sysctl configuration
  # disable ipv6 auto-configuration
  sysctl { 'net.ipv6.conf.all.autoconf': value => '0' }
  sysctl { 'net.ipv6.conf.all.accept_ra': value => '0' }
  sysctl { 'net.ipv6.conf.all.use_tempaddr': value => '0' }

}

node 'monitor' inherits base_node {

  package { ['rrdtool', 'php5']:
    ensure => installed,
  }

  # collectd configuration (server)
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
    typesdb      => [
      '/usr/share/collectd/types.db',
      '/usr/share/collectd/iwinfo_types.db',
      '/usr/share/collectd/kmodem_types.db'
    ]
  }
  class { 'collectd::plugin::network':
    listen => '*',
  }
  class { 'collectd::plugin::rrdcached':
    daemonaddress => 'unix:/var/run/rrdcached.sock',
    datadir       => '/var/lib/collectd/rrd',
  }
  class { 'collectd::plugin::unixsock':
    socketperms => '0666',
  }

  # rrdcached configuration
  class { 'rrdcached':
    restrict_writes => true,
    jump_dir        => '/var/lib/collectd/rrd',
    timeout         => 600,
    delay           => 60,
  }

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    vhost_purge     => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }
  nginx::resource::vhost { 'monitor.berlin.freifunk.net':
    ensure      => present,
    ipv6_enable => true,
    www_root    => '/srv/www/monitor.berlin.freifunk.net',
    index_files => ['index.php'],
    access_log  => '/dev/null',
    error_log   => '/dev/null',
  }
  nginx::resource::location { 'php':
    ensure               => present,
    www_root             => '/srv/www/monitor.berlin.freifunk.net',
    location             => '~ [^/]\.php(/|$)',
    vhost                => 'monitor.berlin.freifunk.net',
    fastcgi              => 'unix:/var/run/php-fpm-monitor.berlin.freifunk.net.sock',
    fastcgi_split_path   => '^(.+?\.php)(/.*)$',
    location_cfg_prepend => {
      fastcgi_param => 'PATH_INFO $fastcgi_path_info',
    }
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
    require  => [
      File['/srv/www'],
      Package['git']
    ]
  }

  file { '/srv/www/monitor.berlin.freifunk.net/conf/config.local.php':
    ensure => present,
    source => 'puppet:///modules/files/config.local.php',
    owner  => 'www-data',
  }

  # type dbs for cgp
  file { '/usr/share/collectd/iwinfo_types.db':
    ensure  => present,
    source  => 'puppet:///modules/files/iwinfo_types.db',
    require => Class['collectd'],
  }
  file { '/usr/share/collectd/kmodem_types.db':
    ensure => present,
    source => 'puppet:///modules/files/kmodem_types.db',
    require => Class['collectd'],
  }
}

node 'firmware' inherits base_node {}
