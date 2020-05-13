node 'config.berlin.freifunk.net' {
  class { 'ff_base': }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::df': }
  class { 'collectd::plugin::disk':
    disks          => ['vda'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    server_purge    => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null'
  }
  nginx::resource::server { 'ip.berlin.freifunk.net':
    access_log           => '/dev/null',
    error_log            => '/dev/null',
    use_default_location => false,
    index_files          => [],
    location_custom_cfg  => {},
    server_cfg_append    => {
      'return' => '301 https://config.berlin.freifunk.net',
    }
  }
  nginx::resource::server { 'config.berlin.freifunk.net':
    ensure      => present,
    ipv6_enable => true,
    access_log  => '/dev/null',
    error_log   => '/dev/null',
    ssl         => true,
    ssl_cert    => '/etc/letsencrypt/live/config.berlin.freifunk.net/fullchain.pem',
    ssl_key     => '/etc/letsencrypt/live/config.berlin.freifunk.net/privkey.pem',
    ssl_dhparam => '/etc/ssl/private/config.berlin.freifunk.net.dh',
    www_root    => '/var/www/nipap-wizard/app/static',
    try_files   => ['$uri', '@nipap-wizard'],
  }
  nginx::resource::location { 'config.berlin.freifunk.net/static':
    ensure   => present,
    ssl      => true,
    server   => 'config.berlin.freifunk.net',
    www_root => '/var/www/nipap-wizard/app/',
    location => '/static',
  }
  nginx::resource::location { '@nipap-wizard':
    ensure              => present,
    ssl                 => true,
    server              => 'config.berlin.freifunk.net',
    location_custom_cfg => {
      'include'    => 'uwsgi_params',
      'uwsgi_pass' => 'unix:/run/uwsgi/app/nipap-wizard/socket',
    },
  }



  apt::key { 'nipap':
    id     => '58E66DF09A12C9D752FD924C4481633C2094AABD',
    source => 'https://spritelink.github.io/NIPAP/nipap.gpg.key',
  }
  apt::source { 'nipap':
    location => 'http://spritelink.github.io/NIPAP/repos/apt',
    release  => 'stable',
    repos    => 'main extra',
    key      => '58E66DF09A12C9D752FD924C4481633C2094AABD',
    require  => Apt::Key['nipap'],
  }

  package { [
    'libffi-dev',
    'libpq-dev',
    'python3-dev',
    'python-flask',
    'python-flask-migrate',
    'python-flask-script',
    'python-flask-sqlalchemy',
    'python-flaskext.wtf',
    'python-psycopg2',
    'uwsgi-plugin-python',
    'uwsgi-plugin-python3',
    'python-pynipap'
  ]:
    ensure  => present,
    require => Apt::Source['nipap'],
  }


  monitor.berlin.freifunk.net.pp buildbot.berlin.freifunk.net.pp config.berlin.freifunk.net.pp vpn03.pp bbbvpn.pp

  # uwsgi configuration
  class { 'uwsgi':
    install_pip        => false,
    install_python_dev => false,
    package_provider   => 'apt',
    emperor_options    => {
      hook-as-root => 'exec:mkdir -p -m 775 /run/uwsgi/app; chown %u:www-data /run/uwsgi/app',
    }
  }
  uwsgi::app { 'nipap-wizard':
    ensure              => present,
    uid                 => 'www-data',
    gid                 => 'www-data',
    application_options => {
      plugins    => 'python',
      socket     => '/run/uwsgi/app/nipap-wizard/socket',
      master     => 'true',
      processes  => '2',
      pythonpath => '/var/www/nipap-wizard/env/lib/python2.7/site-packages/',
      chdir      => '/var/www/nipap-wizard',
      module     => 'manage:app',
      hook-asap  => 'exec:mkdir -p /run/uwsgi/app/%n/',
    }
  }

  # clone nipap-wizard
  vcsrepo { '/var/www/nipap-wizard':
    ensure   => present,
    provider => git,
    owner    => 'www-data',
    source   => 'https://github.com/freifunk-berlin/nipap-wizard.git',
    require  => [
      Package['git']
    ]
  }

  class { 'python':
    virtualenv => 'present',
    dev        => 'present', # needed by psycopg2
  }
  python::virtualenv { '/var/www/nipap-wizard/env':
    ensure       => present,
    requirements => '/var/www/nipap-wizard/requirements.txt',
    owner        => 'www-data',
    group        => 'www-data',
    cwd          => '/var/www/nipap-wizard',
    venv_dir     => '/var/www/nipap-wizard/env',
    systempkgs   => true,
    require      => [
      Class['python'],
      Package[
        'libpq-dev',
        'python-flask',
        'python-flask-migrate',
        'python-flask-script',
        'python-flask-sqlalchemy',
        'python-flaskext.wtf',
        'python-psycopg2',
        'python-pynipap'
      ],
      Vcsrepo['/var/www/nipap-wizard']
    ]
  }

  class { 'postgresql::server':
    datadir => '/data/postgres',

  }


  postgresql::server::db { 'nipap':
    user   => 'nipap',
  password => 'nipap',
  }

  postgresql::server::db { 'wizard':
    user   => 'wizard',
  password => 'wizard',
  }



}
