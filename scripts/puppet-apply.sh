#!/usr/bin/env bash
puppet apply --verbose --show_diff --modulepath=/root/berlin-puppet/puppet/modules \
  puppet/manifests/
