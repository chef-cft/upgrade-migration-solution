#!/bin/bash
customer_id="$1"
datacollector_token="$2"

if [ ! -e "/bin/hab" ]; then
  curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash
fi

if grep "^hab:" /etc/passwd > /dev/null; then
  echo "Hab user exists"
else
  useradd hab && true
fi

if grep "^hab:" /etc/group > /dev/null; then
  echo "Hab group exists"
else
  groupadd hab && true
fi

pkg_origin='migration'
pkg_name='fingerprinter'

echo "By running this script, you accept the Chef license agreement"
hab license accept

echo "Installing $pkg_origin/$pkg_name"
hab pkg install $pkg_origin/$pkg_name

echo "Creating configuration overrides"
mkdir -p /hab/user/fingerprinter/config/
cat > /hab/user/fingerprinter/config/user.toml <<EOF
[chef_license]
acceptance = "accept-no-persist"

[automate]
enable = true
server_url = "https://migration-${customer_id}.success.chef.co/data-collector/v0/"
token = "${datacollector_token}"
EOF

echo "Determing pkg_prefix for $latest_hart_file"
pkg_prefix=$(find /hab/pkgs/$pkg_origin/$pkg_name -maxdepth 2 -mindepth 2 | sort | tail -n 1)

echo "Found $pkg_prefix"

cd $pkg_prefix
hab pkg exec $pkg_origin/$pkg_name chef-client -z -c $pkg_prefix/config/bootstrap-config.rb
