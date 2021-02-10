node 'download-master.berlin.freifunk.net' {
  class { 'ff_base': }

  package { ['libnginx-mod-http-fancyindex']:
    ensure => installed,
  }

  # add users nick and akira with shared group falter

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

  class { 'letsencrypt':
    unsafe_registration => true,
    package_ensure      => 'latest',
  }

  letsencrypt::certonly { 'download-master.berlin.freifunk.net':
    domains              => [
       'download-master.berlin.freifunk.net',
    ],
    plugin               => 'webroot',
    webroot_paths        => [
      '/var/www/download-master.berlin.freifunk.net'
    ],
    manage_cron          => true,
    cron_success_command => '/bin/systemctl reload nginx.service',
  }

  class { 'nginx':
    confd_purge     => true,
    server_purge    => true,
    manage_repo     => false,
    http_access_log => '/dev/null',
    nginx_error_log => '/dev/null',
    server_tokens   => off,
    gzip            => on,
    gzip_vary       => on,
    gzip_types      => "text/plain application/xml",
    gzip_min_length => "1000",
    ssl_protocols   => "TLSv1.1 TLSv1.2 TLSv1.3",

  }
  nginx::resource::server { 'default_server':
    ensure              => present,
    ipv6_enable         => true,
    ipv6_listen_options => '',
    ssl                 => true,
    ssl_cert            => '/etc/letsencrypt/live/download-master.berlin.freifunk.net/fullchain.pem',
    ssl_key             => '/etc/letsencrypt/live/download-master.berlin.freifunk.net/privkey.pem',
    ssl_dhparam         => '/etc/ssl/private/dhparam.pem',
    www_root            => '/var/www/$host/',
    http2               => 'on',
    server_cfg_append   => {
      fancyindex            => on,
      fancyindex_exact_size => off,
      fancyindex_ignore     => "index-assets",
    }
  }
}
