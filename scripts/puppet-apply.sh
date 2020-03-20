#!/usr/bin/env bash
puppet apply --verbose --modulepath=/root/berlin-puppet/puppet/modules \
  puppet/manifests/site.pp
