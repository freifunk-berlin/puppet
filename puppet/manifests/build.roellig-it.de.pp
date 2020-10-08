node 'build.roellig-it.de' {
  class { 'ff_base': }

  package { [
    'rsync',
    'ccache',
    'openjdk-11-jre',
    'asciidoc',
    'bash',
    'binutils',
    'bzip2',
    'flex',
    'git-core',
    'g++',
    'gcc',
    'util-linux',
    'gawk',
    'help2man',
    'intltool',
    'libelf-dev',
    'zlib1g-dev',
    'make',
    'libncurses-dev',
    'libssl-dev',
    'patch',
    'perl-modules',
    'python2-dev',
    'python3-dev',
    'unzip',
    'wget',
    'gettext',
    'xsltproc'
  ]:
    ensure => present
  }


  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::df': }
  class { 'collectd::plugin::disk':
    disks          => ['vda', 'vdb'],
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



  class { 'nginx':
    confd_purge     => true,
    server_purge    => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }

  nginx::resource::server { 'build.roellig-it.de':
    ensure                  => present,
    ipv6_enable             => true,
    access_log              => '/dev/null',
    error_log               => '/dev/null',
    proxy                   => 'http://127.0.0.1:8080',
    ssl_redirect            => true,
    ssl                     => true,
    ssl_cert                => '/etc/letsencrypt/live/build.roellig-it.de/fullchain.pem',
    ssl_key                 => '/etc/letsencrypt/live/build.roellig-it.de/privkey.pem',

    proxy_set_header        => ['Host $host:$server_port',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme'],

    proxy_redirect          => 'http://127.0.0.1:8080 https://build.roellig-it.de',
    proxy_http_version      => '1.1',
    proxy_request_buffering => 'off',

  }
  nginx::resource::location { '/.well-known':
    ensure    => present,
    #ssl       => true,
    server    => "build.roellig-it.de",
    www_root  => '/var/www/letsencrypt',
    autoindex => 'off',
    try_files => ['$uri $uri/ =404'],
  }

  class { letsencrypt:
    unsafe_registration => true,
    renew_cron_ensure   => 'present',
  }
  letsencrypt::certonly { 'build.roellig-it.de':
    domains       => ['build.roellig-it.de'],
    plugin        => 'webroot',
    webroot_paths => ['/var/www/letsencrypt'],
  }

  # Jenkins
  apt::key { 'jenkins':
    id     => '62A9756BFD780C377CF24BA8FCEF32E745F2C3D5',
    source => 'https://pkg.jenkins.io/debian/jenkins.io.key',
  }

  apt::source { 'jenkins':
    location => 'https://pkg.jenkins.io/debian-stable/',
    repos    => 'binary/',
    release  => '',
  }
}
