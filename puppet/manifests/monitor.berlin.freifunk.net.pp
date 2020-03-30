node 'monitor' {

  class { 'ff_base': }

  package { ['rrdtool']:
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
  collectd::plugin::network::listener { '*':
    port => 25826,
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
    timeout         => 1800,
    delay           => 600,
  }

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    server_purge    => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }
  nginx::resource::server { 'monitor.berlin.freifunk.net':
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
    server               => 'monitor.berlin.freifunk.net',
    fastcgi              => 'unix:/var/run/php-fpm-monitor.berlin.freifunk.net.sock',
    fastcgi_split_path   => '^(.+?\.php)(/.*)$',
    location_cfg_prepend => {
      fastcgi_param => 'PATH_INFO $fastcgi_path_info',
    }
  }

  # php-fpm configuration (nginx backend)
  class { 'php_fpm': }
  php_fpm::pool { 'monitor.berlin.freifunk.net':
    listen => '/var/run/php-fpm-monitor.berlin.freifunk.net.sock',
  }

  # root directory for monitor.berlin.freifunk.net
  file { ['/srv/www']:
    ensure  => directory,
    owner   => 'www-data',
    require => Class['nginx'],
  }

  # Collectd Graph Panel
  vcsrepo { '/srv/www/monitor.berlin.freifunk.net':
    ensure   => latest,
    provider => git,
    owner    => 'www-data',
    source   => 'https://github.com/pommi/CGP/',
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

  # add assocs.json plugin for cgp
  file { '/srv/www/monitor.berlin.freifunk.net/plugin/assocs.json':
    ensure => present,
    source => 'puppet:///modules/files/assocs.json',
    owner  => 'www-data',
  }

  # type dbs for cgp
  file { '/usr/share/collectd/iwinfo_types.db':
    ensure  => present,
    source  => 'puppet:///modules/files/iwinfo_types.db',
    require => Class['collectd'],
  }
  file { '/usr/share/collectd/kmodem_types.db':
    ensure  => present,
    source  => 'puppet:///modules/files/kmodem_types.db',
    require => Class['collectd'],
  }
}
