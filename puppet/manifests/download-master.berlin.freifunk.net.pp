node 'download-master.berlin.freifunk.net' {
  class { 'ff_base': }

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
}
