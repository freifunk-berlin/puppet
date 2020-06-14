node 'buildbot.berlin.freifunk.net' {
  class { 'ff_base': }
  class { 'ff_base::buildbot' : }

  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::df': }
  class { 'collectd::plugin::disk':
    disks          => ['vda','vdb'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::interface':
    interfaces     => ['ens3'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }

  file { [
    '/usr/local/src/www/htdocs/buildbot',
    '/usr/local/src/www/htdocs/buildbot/unstable',
    '/usr/local/src/www/htdocs/buildbot/stable',
  ]:
    ensure  => directory,
    owner   => 'www-data',
    group   => 'buildbot',
    mode    => '0755',
    before  => Class['nginx']
  }
  class { 'letsencrypt':
    unsafe_registration => true,
    package_ensure      => 'latest',
  }

  letsencrypt::certonly { 'buildbot.berlin.freifunk.net':
    domains              => [
      'buildbot.berlin.freifunk.net',
      'firmware.berlin.freifunk.net',
    ],
    plugin               => 'webroot',
    webroot_paths        => [
      '/usr/local/src/www/htdocs',
      '/usr/local/src/www/htdocs/buildbot',
    ],
    manage_cron          => true,
    cron_success_command => '/bin/systemctl reload nginx.service',
  }

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    server_purge    => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }
  nginx::resource::server { 'firmware.berlin.freifunk.net':
    ensure              => present,
    ipv6_enable         => true,
    # fix for https://serverfault.com/questions/277653/nginx-name-based-virtual-hosts-on-ipv6
    ipv6_listen_options => '',
    access_log          => '/dev/null',
    error_log           => '/dev/null',
    ssl                 => true,
    ssl_cert            => '/etc/letsencrypt/live/firmware.berlin.freifunk.net/fullchain.pem',
    ssl_key             => '/etc/letsencrypt/live/firmware.berlin.freifunk.net/privkey.pem',
    ssl_dhparam         => '/etc/ssl/private/buildbot.berlin.freifunk.net.dh',
    www_root            => '/usr/local/src/www/htdocs/buildbot',
    autoindex           => on,
  }
  nginx::resource::server { 'buildbot.berlin.freifunk.net':
    ensure      => present,
    ipv6_enable => true,
    access_log  => '/dev/null',
    error_log   => '/dev/null',
    proxy       => 'http://buildbot',
    ssl         => true,
    ssl_cert    => '/etc/letsencrypt/live/buildbot.berlin.freifunk.net/fullchain.pem',
    ssl_key     => '/etc/letsencrypt/live/buildbot.berlin.freifunk.net/privkey.pem',
    ssl_dhparam => '/etc/ssl/private/buildbot.berlin.freifunk.net.dh',
  }
  nginx::resource::location { '/.well-known':
    ensure    => present,
    ssl       => true,
    server    => 'buildbot.berlin.freifunk.net',
    www_root  => '/usr/local/src/www/htdocs',
    autoindex => 'off',
  }
  nginx::resource::location { '/buildbot':
    ensure    => present,
    ssl       => true,
    server    => 'buildbot.berlin.freifunk.net',
    www_root  => '/usr/local/src/www/htdocs',
    autoindex => 'on',
  }
  nginx::resource::location { '/ws':
    ensure             => present,
    ssl                => true,
    server             => 'buildbot.berlin.freifunk.net',
    proxy              => 'http://buildbot',
    proxy_http_version => '1.1',
    proxy_set_header   => [
      'Upgrade $http_upgrade',
      'Connection upgrade',
    ],
  }
  nginx::resource::upstream { 'buildbot':
    ensure  => present,
    members => {'localhost:8010' =>  {
        server => 'localhost',
        port   => 8010,
      },

    }

  }
  vcsrepo { '/usr/local/src/buildbot':
    ensure   => latest,
    provider => git,
    owner    => 'buildbot',
    source   => 'https://github.com/freifunk-berlin/buildbot',
    require  => [
      Package['git']
    ]
  }

  class { 'python':
    virtualenv => 'present',
  }
  python::virtualenv { '/usr/local/src/buildbot/masters/master/env':
    ensure       => present,
    version      => '3',
    owner        => 'buildbot',
    group        => 'buildbot',
    cwd          => '/usr/local/src/buildbot/masters/master',
    venv_dir     => '/usr/local/src/buildbot/masters/master/env',
    requirements => '/usr/local/src/buildbot/masters/master/requirements.txt',
    require      => [
      Class['python'],
      Vcsrepo['/usr/local/src/buildbot']
    ]
  }
}
