# migration-upgrade

Tool for Chef 15 upgrade and Effortless migration

## Example output from chef-server

```
Version: Count
nil: {"nil"=>41, "redhat_7.2"=>5}
12.13.37: {"windows_6.3.9600"=>2, "redhat_7.2"=>2}
12.19.36: {"windows_6.3.9600"=>85, "redhat_7.2"=>42, "redhat_6.10"=>4, "redhat_6.8"=>2}
12.21.12: {"windows_6.3.9600"=>1}
12.21.14: {"windows_6.3.9600"=>2}
12.21.3: {"windows_6.3.9600"=>4, "windows_10.0.14393"=>2}
12.21.4: {"windows_6.3.9600"=>2, "redhat_7.3"=>2}
12.22.1: {"windows_6.3.9600"=>2}
12.22.5: {"windows_6.3.9600"=>1}
12.8.1: {"redhat_7.2"=>2}
14.0.183: {"windows_10.0.14393"=>1}
14.10.9: {"redhat_7.6"=>3}
14.11.21: {"windows_10.0.14393"=>66, "redhat_7.6"=>27}
14.12.3: {"redhat_7.6"=>1}
14.12.9: {"redhat_7.5"=>31, "windows_10.0.14393"=>53, "redhat_7.6"=>4}
14.13.11: {"windows_10.0.14393"=>45, "redhat_7.5"=>1}
14.2.0: {"redhat_7.5"=>223, "windows_10.0.14393"=>446, "windows_6.3.9600"=>70, "redhat_7.6"=>2}
14.4.56: {"windows_10.0.14393"=>194, "redhat_7.5"=>8, "redhat_7.6"=>8}
14.5.27: {"redhat_7.2"=>2}
14.5.33: {"redhat_7.6"=>28, "redhat_7.5"=>16}
```

## Upgrade Steps
- Fetch all nodes from server
- Create a list of unique run lists
- If any of those run_list combos have a node on the server running Chef 15+ then skip it since we know it works on a modern Infra Client
- For each run list combination download all the cookbooks in that run list from the server into unique directories on the local host
- Run cookstyle / foodcritic against those directories alerting on just the deprecation rules. Create a report of code changes that will need to be made per run list combination


## Comparison - Chef Infra | Effortless

|Feature|Chef Infra|Effortless|
|-------|----------|----------|
|**chef-client upgrade**|[Chef Client Updater Cookbook](https://github.com/chef-cookbooks/chef_client_updater)|[chef/chef-client Hab Package](https://bldr.habitat.sh/#/pkgs/chef/chef-client/latest)|
|**Organizations**|[Chef Server Orgs](https://docs.chef.io/server_orgs.html)|[Habitat Origins](https://www.habitat.sh/docs/using-builder/#builder-origin)|
|**Environments**|[Chef Environments](https://docs.chef.io/environments.html)|[Habitat Channels](https://www.habitat.sh/docs/using-habitat/#continuous-deployment-using-channels)|
|**Roles**|stored in `*.json`, hosted in Chef Infra Server|*see "Role Cookbooks"|
|**Role Cookbooks**|[Role Cookbook Model](https://github.com/chef-cft/chef-examples/blob/master/examples/RoleCookbookModel.md)|Roles and Role Cookbooks will migrate to a [Habitat Channel](https://www.habitat.sh/docs/using-habitat/#continuous-deployment-using-channels) for each unique endpoint|
|**Data Bags**|stored in `*.json`, hosted in Chef Infra Server||
|**Environment-level Attributes**|stored in `*.json`, hosted in Chef Infra Server||
|**Environment Conditionals**|[`case node.chef_environment`](https://stackoverflow.com/questions/19638372/is-it-possible-to-get-current-environment-in-the-attribute-files)||
|**Knife Commands**|||
||`ssh`|no equivalent + not recommended|
||`search`|[Visibility in Automate](https://automate.chef.io/)|
||`node`|[Visibility in Automate](https://automate.chef.io/)|
||`vault`|we recommend using an application specifically focused on secrets management|
|**Application Orchestration**|combination of bespoke pipelines, `knife` commands, and other methods to get Chef Infra to converge changes in a specific progression|built-in binding (service contracts), combined with service groups and supervisor rings allow for application lifecycle changes in a controlled, well defined and standardized manner

# UX Command Flow

## Upgrade Migration Env Setup

### things we need in the environment
0. workstation
1. chef-server
  * cookbooks
  * roles
  * environments
  * data_bags
  * nodes
2. bitbucket (git)

### Commands we run to set up environment

`terraform plan`
`terraform apply`

### Implementation

1. terraform code for building at least one VM
2. habitat package for application
3.

## Post Environment Setup

### Cookbook Upgrade to Chef 15

Pull down production cookbooks

`knife download /cookbooks`

Run cookstyle and other tooling on cookbooks to give assessment deprecations and chef-server ie search/databags use

`cookstyle /path/to/cookbook`

Confirm running of auto correct of Chef 15 deprecations based on assessment

* need to correct on a branch

`cookstyle -a .`

`hab plan init`

edit plan and add cookbook scaffold

```
pkg_name=cookbook
pkg_origin=chef
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_upstream_url="http://chef.io"
pkg_scaffolding="chef/scaffolding-chef-cookbook"
```

add pipeline description ie Jenkinsfile for build

`Jenkinsfile`

Push cookbook branch to source control

`git push origin branchname`

### Migration to Effortless

download all relevant chef server information for the nodes and their configurations

`knife download roles environments data_bags`

run the migration accel tool?

`chef migrate PATHTODOWNLOAD`

What is the job the migrate tool is doing?
1. filter data from chef-server
2. analyze the data
3. figure out what is 'widest group of uniqueness'
4. naming (need a name for each new set of same nodes)
5. mapping (somehow make sure we put the right package on the right node)

To build a data structure that then can be mapped through a templatized habitat plan.

This should output a set of habitat plans that can build packages to deliver same content to the correct nodes

Example output:

```
pkg_name=chef=named-infra-policy
pkg_origin=chef
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=("Apache-2.0")
pkg_upstream_url="http://chef.io"

pkg_deps=(
  chef/chef-client
  chef/inspec-client
  jmfamily/group-configuration
  jmfamily/base-cookbook
  jmfamily/app-one-cookbook
  premium-chef/CIS-2
)
```
Write out file for policy -> node mapping

`chef migrate export policy-map`

Add 'switchover cookbook' to the runlist of all our nodes

1. add the switchover cookbook to all node runlists
2. set attribute to false for `switchbook::do-switchover = false`

Change chef attribute from false to true to trigger switchover

`switchbook::do-switchover = true`

3. run chef-client on all nodes
