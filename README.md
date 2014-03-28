# berlin.freifunk.net puppet deployment scripts

## Install

Copy `./scripts/install.sh` into the home directory of the root user. Run the
script. The script will install all necessary packages and will run puppet once.
Make sure the hostname of the machine is correct once you run puppet.

## Execute puppet

Use `./scripts/puppet-apply.sh` to start a puppet run.
