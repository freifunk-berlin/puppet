node 'l105-bbbvpn' {
  class { 'ff_base': }
  class { 'bbbdigger':
    address        => '77.87.49.11',
    interface      => 'eth0',
    mesh_address   => '10.230.38.205',
    mesh_interface => 'backbone',
    tunnel_address => '10.36.193.1/24',
    dhcp_range     => '10.36.193.4,10.36.193.254,255.255.255.0,1h',
    bbbdigger_name => 'b.bbb-vpn',
  }
}