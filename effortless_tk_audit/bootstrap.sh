#!/bin/bash
echo "pkg_origin is $1"
echo "pkg_name is $2"
export HAB_LICENSE="accept-no-persist"
export CHEF_LICENSE="accept-no-persist"
export HAB_ORIGIN=yourorigin

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

pkg_origin=$1
pkg_name=$2

cd /tmp/habitat
hab pkg install core/hab-studio
hab origin key generate
hab studio run CHEF_LICENSE='accept-no-persist' build
source results/last_build.env
hab pkg install results/$pkg_artifact
echo "Building $pkg_origin/$pkg_name"

echo "Determine pkg_prefix for $pkg_artifact"
pkg_prefix=$(find "/hab/pkgs/$pkg_origin/$pkg_name" -maxdepth 2 -mindepth 2 | sort | tail -n 1)
echo "Found: $pkg_prefix"

# Execute InSpec inside the package (ignoring control failures)
echo "Running Chef InSpec in $pkg_origin/$pkg_name"

hab pkg exec "$pkg_origin/$pkg_name" inspec exec  "$pkg_prefix/*.tar.gz"

# Capture exit code of Chef InSpec command
exit_code=$?

# Exit 0 if non-zero exit is related to control failures
if [ $exit_code -ge 100 ]; then
  exit 0
else
  echo "InSpec exited $exit_code, see https://www.inspec.io/docs/reference/cli/#exec"
  exit 1
fi
