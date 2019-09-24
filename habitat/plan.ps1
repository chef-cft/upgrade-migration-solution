$pkg_name="fingerprinter"
$pkg_origin="migration"
$pkg_version=Get-Content -Path ..\VERSION
$pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
$pkg_license=("Apache-2.0")
$pkg_upstream_url="http://chef.io"
$pkg_build_deps=@("core/chef-dk")
$pkg_deps=@(
  "core/cacerts"
  "stuartpreston/chef-client" # https://github.com/habitat-sh/habitat/issues/6671
)
$pkg_scaffolding="chef/scaffolding-chef-infra"
$scaffold_policy_name="Policyfile"
$scaffold_policyfiles_path="../fingerprinter/"
