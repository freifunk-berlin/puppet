# berlin.freifunk.net puppet deployment scripts

## Install

Copy `./scripts/install.sh` into the home directory of the root user. Run the
script. The script will install all necessary packages and will run puppet once.
Make sure the hostname of the machine is correct once you run puppet.

## Execute puppet

Use `./scripts/puppet-apply.sh` to start a puppet run.

## Update puppet modules

To update the puppet modules use `librarian-puppet`. It's a module/package
manager for puppet modules. Make sure you are in the `puppet` directory:

```
  cd puppet
  librarian-puppet update
  git add Puppetfile.lock
  git commit -m "update puppet modules"
```

## Common use cases

### Update config.local-php of CGP (monitor.berlin.*)

To update the index of our [monitoring site](http://monitor.berlin.freifunk.net)
you should first clone the [berlin-puppet-files](https://github.com/freifunk/berlin-puppet-files)
repository. Change the index in `files/config.local.php`. Commit your changes
and push the changes.

The next step is to update the puppet modules. *berlin-puppet-files* is a puppet
module that we use in the deploy process. Please follow the instructions in the
**Update puppet modules** section. Make sure you push the changes to the remote machine
and execute the update there as well (librarian-puppet update).

Once the modules are updated on the remote machine start a puppet run. Please
follow the instructions in the **Execute puppet** section.

## Certificates and private Keys

If you need a private certificate or private key that is part of the deployment
process please ask http://github.com/booo for help or contact the mailing list
(berlin@berlin.freifunk.net). We keep offline backups of the keys.

Copy certs and keys to `/etc/ssl/{certs, private}`.

Additional information can be found in the wiki:

http://wiki.freifunk.net/StartSSL
