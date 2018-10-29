class base_node() {

  class { 'apt': }

  # update packages before we install any
  exec { "apt-update":
    command => "/usr/bin/apt-get update"
  }
  Exec["apt-update"] -> Package <| |>

  # do not install recommended packages
  Package {
    install_options => ['--no-install-recommends'],
  }

  # list of base packages we deploy on every node
  package { [
    'byobu',
    'dstat',
    'git',
    'htop',
    'iputils-tracepath',
    'man-db',
    'mailutils',
    'mtr',
    'screen',
    'tcpdump',
    'tmux',
    'vim'
  ]:
    ensure => installed,
  }

  # install security updates
  class { 'unattended_upgrades': }

  class { 'ntp': }

  # sysctl configuration
  # disable ipv6 auto-configuration
  sysctl { 'net.ipv6.conf.all.autoconf': value => '0' }
  sysctl { 'net.ipv6.conf.all.accept_ra': value => '0' }
  sysctl { 'net.ipv6.conf.all.use_tempaddr': value => '0' }

  # configure smart host mail setup
  #class { 'exim4':
  #  configtype => 'satellite',
  #  smarthost  => 'ssl.coulmann.de',
  #}
  ## set mail alias for root
  #mailalias { 'root':
  #  ensure    => present,
  #  name      => 'root',
  #  recipient => 'noc@berlin.freifunk.net',
  #  target    => "/etc/email-addresses",
  #}


}

node 'monitor' {

  class { 'base_node': }

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
  collectd::plugin::network::listener{'*':
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
    timeout         => 600,
    delay           => 120,
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
    ensure => present,
    source => 'puppet:///modules/files/kmodem_types.db',
    require => Class['collectd'],
  }
}

node 'buildbot.berlin.freifunk.net' {
  class { 'base_node': }

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    vhost_purge     => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }
  nginx::resource::vhost { 'buildbot.berlin.freifunk.net':
    ensure      => present,
    ipv6_enable => true,
    access_log  => '/dev/null',
    error_log   => '/dev/null',
    proxy       => 'http://buildbot',
    ssl         => true,
    ssl_cert    => "/etc/ssl/certs/buildbot.berlin.freifunk.net.cert",
    ssl_key     => "/etc/ssl/private/buildbot.berlin.freifunk.net.key",
    ssl_dhparam => "/etc/ssl/private/buildbot.berlin.freifunk.net.dh",
  }
  nginx::resource::location { '/buildbot':
    ensure    => present,
    ssl       => true,
    vhost     => 'buildbot.berlin.freifunk.net',
    www_root  => '/usr/local/src/www/htdocs',
    autoindex => 'on',
  }
  nginx::resource::upstream { 'buildbot':
    ensure  => present,
    members => ['localhost:8010'],
  }

  file { [
    '/usr/local/src/www/htdocs/buildbot',
    '/usr/local/src/www/htdocs/buildbot/unstable',
    '/usr/local/src/www/htdocs/buildbot/stable',
  ]:
    ensure  => directory,
    owner   => 'buildbot',
  }
  # add cron file that removes old buildbot firmware builds
  file { '/etc/cron.hourly/buildbot-remove-old-builds':
    ensure => present,
    source => 'puppet:///modules/files/buildbot-remove-old-builds.sh',
  }
}

node 'config.berlin.freifunk.net' {
  class { 'base_node': }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::df':}
  class {'collectd::plugin::disk':
    disks => ['vda'],
    ignoreselected => false,
  }
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}

  # nginx configuration
  class { 'nginx':
    confd_purge     => true,
    vhost_purge     => true,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
  }
  nginx::resource::vhost { 'ip.berlin.freifunk.net':
    access_log           => '/dev/null',
    error_log            => '/dev/null',
    use_default_location => false,
    index_files          => [],
    location_custom_cfg  => {},
    vhost_cfg_append => {
      'return' => '301 https://config.berlin.freifunk.net',
    }
  }
  nginx::resource::vhost { 'config.berlin.freifunk.net':
    ensure      => present,
    ipv6_enable => true,
    access_log  => '/dev/null',
    error_log   => '/dev/null',
    ssl         => true,
    ssl_cert    => "/etc/ssl/certs/config.berlin.freifunk.net.cert",
    ssl_key     => "/etc/ssl/private/config.berlin.freifunk.net.key",
    ssl_dhparam => "/etc/ssl/private/config.berlin.freifunk.net.dh",
    www_root    => '/var/www/nipap-wizard/app/static',
    try_files   => ['$uri', '@nipap-wizard'],
  }
  nginx::resource::vhost { 'ca.berlin.freifunk.net':
    ensure              => present,
    ipv6_enable         => true,
    # fix for https://serverfault.com/questions/277653/nginx-name-based-virtual-hosts-on-ipv6
    ipv6_listen_options => '',
    access_log          => '/dev/null',
    error_log           => '/dev/null',
    ssl                 => true,
    ssl_cert            => "/etc/ssl/certs/ca.berlin.freifunk.net.cert",
    ssl_key             => "/etc/ssl/private/ca.berlin.freifunk.net.key",
    ssl_dhparam         => "/etc/ssl/private/ca.berlin.freifunk.net.dh",
    www_root            => '/var/www/ca.berlin.freifunk.net/static', # TODO check this
    try_files           => ['$uri', '@ca.berlin.freifunk.net'],
  }
  nginx::resource::location { 'config.berlin.freifunk.net/static':
    ensure   => present,
    ssl      => true,
    vhost    => 'config.berlin.freifunk.net',
    www_root => '/var/www/nipap-wizard/app/',
    location => '/static',
  }
  nginx::resource::location { '@nipap-wizard':
    ensure              => present,
    ssl                 => true,
    vhost               => 'config.berlin.freifunk.net',
    location_custom_cfg => {
      'include'         => 'uwsgi_params',
      'uwsgi_pass'      => 'unix:/run/uwsgi/app/nipap-wizard/socket',
    },
  }
  nginx::resource::location { '@ca.berlin.freifunk.net':
    ensure              => present,
    ssl                 => true,
    vhost               => 'ca.berlin.freifunk.net',
    location_custom_cfg => {
      'include'         => 'uwsgi_params',
      'uwsgi_pass'      => 'unix:/run/uwsgi/app/ca.berlin.freifunk.net/socket',
    },
  }

  apt::key { 'nipap':
    key        => '4481633C2094AABD',
    key_source => 'https://spritelink.github.io/NIPAP/nipap.gpg.key',
  }
  apt::source { 'nipap':
    location => 'http://spritelink.github.io/NIPAP/repos/apt',
    release  => 'stable',
    repos    => 'main extra',
    key      => '4481633C2094AABD',
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

  # uwsgi configuration
  class { 'uwsgi':
    install_pip        => false,
    install_python_dev => false,
    package_provider   => 'apt',
    emperor_options    => {
      hook-as-root     => 'exec:mkdir -p -m 775 /run/uwsgi/app; chown %u:www-data /run/uwsgi/app',
    }
  }
  uwsgi::app{ 'nipap-wizard':
    ensure              => present,
    uid                 => 'www-data',
    gid                 => 'www-data',
    application_options => {
      plugins           => 'python',
      socket            => '/run/uwsgi/app/nipap-wizard/socket',
      master            => 'true',
      processes         => '2',
      pythonpath        => '/var/www/nipap-wizard/env/lib/python2.7/site-packages/',
      chdir             => '/var/www/nipap-wizard',
      module            => 'manage:app',
      hook-asap         => 'exec:mkdir -p /run/uwsgi/app/%n/',
    }
  }
  uwsgi::app{ 'ca.berlin.freifunk.net':
    ensure              => present,
    uid                 => 'www-data',
    gid                 => 'www-data',
    application_options => {
      plugins           => 'python3',
      socket            => '/run/uwsgi/app/ca.berlin.freifunk.net/socket',
      master            => 'true',
      processes         => '2',
      pythonpath        => '/var/www/ca.berlin.freifunk.net/env/lib/python3.4/site-packages/',
      chdir             => '/var/www/ca.berlin.freifunk.net',
      module            => 'manage:app',
      hook-asap         => 'exec:mkdir -p /run/uwsgi/app/%n/',
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
  # clone ca.berlin.freifunk.net
  vcsrepo { '/var/www/ca.berlin.freifunk.net':
    ensure   => present,
    provider => git,
    owner    => 'www-data',
    source   => 'https://github.com/freifunk-berlin/ca.berlin.freifunk.net.git',
    require  => [
      Package['git']
    ]
  }

  class { 'python' :
    virtualenv => true,
    dev    => true, # needed by psycopg2
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
  python::virtualenv { '/var/www/ca.berlin.freifunk.net/env':
    ensure       => present,
    version      => '3',
    virtualenv   => 'virtualenv',
    requirements => '/var/www/ca.berlin.freifunk.net/requirements.txt',
    owner        => 'www-data',
    group        => 'www-data',
    cwd          => '/var/www/ca.berlin.freifunk.net',
    venv_dir     => '/var/www/ca.berlin.freifunk.net/env',
    systempkgs   => true,
    require      => [
      Class['python'],
      Package[
        'libffi-dev',
        'libpq-dev',
        'python-flask',
        'python-flask-migrate',
        'python-flask-script',
        'python-flask-sqlalchemy',
        'python-flaskext.wtf',
        'python-psycopg2',
        'python-pynipap',
        'python3-dev'
      ],
      Vcsrepo['/var/www/ca.berlin.freifunk.net']
    ]
  }

  class { 'postgresql::server': }
}

node 'vpn03a' {
  class { 'base_node': }
  class { 'vpn03':
    inet_add => '77.87.48',
    inet_min => '128',
    inet_max => '191',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03b' {
  class { 'base_node': }
  class { 'vpn03':
    inet_dev => 'ens3',
    inet_add => '77.87.49',
    inet_min => '249',
    inet_max => '254',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03c' {
  class { 'base_node': }
  class { 'vpn03':
    inet_dev => 'ens3',
    inet_add => '77.87.49',
    inet_min => '241',
    inet_max => '246',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03d' {
  class { 'base_node': }
  class { 'vpn03':
    inet_add => '185.66.195',
    inet_min => '250',
    inet_max => '251',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03e' {
  class { 'base_node': }
  class { 'vpn03':
    inet_add => '77.87.50',
    inet_min => '241',
    inet_max => '254',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03f' {
  class { 'base_node': }
  class { 'vpn03':
    inet_add => '193.96.224',
    inet_min => '243',
    inet_max => '244',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'vpn03g' {
  class { 'base_node': }
  class { 'vpn03':
    inet_add => '185.197.132',
    inet_min => '10',
    inet_max => '10',
    inet_dev => 'ens3',
  }
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
  }
  class {'collectd::plugin::cpu':}
  class {'collectd::plugin::conntrack':}
  class {'collectd::plugin::interface':
    interfaces     => ['ens3'],
    ignoreselected => false,
  }
  class {'collectd::plugin::load':}
  class {'collectd::plugin::memory':}
  collectd::plugin::network::server {'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class {'collectd::plugin::processes':}
  class {'collectd::plugin::swap':}
}

node 'l105-bbbvpn' {
  class { 'base_node': }
  class { 'bbbdigger':
    address          => '77.87.49.11',
    interface        => 'eth0',
    mesh_address     => '10.230.38.205',
    mesh_interface   => 'backbone',
    tunnel_address   => '10.36.193.1/24',
    dhcp_range       => '10.36.193.4,10.36.193.254,255.255.255.0,1h',
    name             => 'b.bbb-vpn',
  }
}
