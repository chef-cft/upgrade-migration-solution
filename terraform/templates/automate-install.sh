#!/bin/bash -ex

mkdir -p /etc/chef-automate
mv /tmp/automate-config.toml /etc/chef-automate/config.toml

/var/cache/marketplace/chef-automate deploy /etc/chef-automate/config.toml --accept-terms-and-mlsa --skip-preflight --airgap-bundle /var/cache/marketplace/chef-automate.bundle

# reset the admin user password to the one specified in the TF config
chef-automate iam admin-access restore '${automate_admin_password}'

# Upgrade to IAMv2
chef-automate iam upgrade-to-v2
