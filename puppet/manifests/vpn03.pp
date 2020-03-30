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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
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
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
}

node 'vpn03c' {
  class { 'ff_base': }
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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
}

node 'vpn03d' {
  class { 'ff_base': }
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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
}

node 'vpn03e' {
  class { 'ff_base': }
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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
}

node 'vpn03f' {
  class { 'ff_base': }
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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['eth0'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['eth0', 'tun-udp'],
    verboseinterfaces => ['eth0', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
}

node 'vpn03g' {
  class { 'ff_base': }
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
  class { 'collectd::plugin::cpu': }
  class { 'collectd::plugin::conntrack': }
  class { 'collectd::plugin::interface':
    interfaces     => ['ens3'],
    ignoreselected => false,
  }
  class { 'collectd::plugin::load': }
  class { 'collectd::plugin::memory': }
  collectd::plugin::network::server { 'monitor.berlin.freifunk.net':
    port => 25826,
  }
  class { 'collectd::plugin::netlink':
    interfaces        => ['ens3', 'tun-udp'],
    verboseinterfaces => ['ens3', 'tun-udp'],
    ignoreselected    => false,
  }
  class { 'collectd::plugin::processes': }
  class { 'collectd::plugin::swap': }
  class { 'communitytunnel':
    interface => 'ens3',
    address   => '185.197.132.10',
  }
}