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

## Migration Pattern

### Current Production Cookbooks
1. Gather list of production cookbooks.
1. Pull down first cookbook for local testing.
1. Create repo in SCM if the cookbook doesn't already have it's own repo (1-per-cookbook), commit cookbook to SCM before changes are made (if already in SCM, verify diff).
1. Create new Chef-15 branch for the repo locally, switch to that branch for all further work.
1. Run Cookstyle, Foodcritic + other tools on cookbook.
1. Assess the changes needed.
1. Confirm changes required, make manual changes if needed.
1. Some changes will have the possiblity to be auto-remediated.
1. Continue process until all needed changes to have cookbook working with Chef Infra Client 15 are remediated and the cookbook tests successfully in Test Kitchen.
1. Add Habitat Plan to cookbook.
1. Commit changes to repo.
1. Commit will trigger build webhook to fire, the Habitat Package will be built and stored in Hab Depot via job server.
1. The job server will also perform reverse dependency lookup and pull down all cookbooks that the primary cookbook depends upon, all the way up the chain.
1. The job server will determine if there are any attributes referenced that are dependent upon envrionments (either local or Chef Infra Envrionment attributes), as well as any references to data bags.
1. Each cookbook will be packaged into it's own Habitat pkg.
1. The end result will be a Habitat Packaged cookbook stored in Hab Depot, along with a manifest of all newly created dependency cookbook packages it depends upon (stored in package and as output) as well as a manifest of all Environment-level attributes and Data Bag references.

#### Output of Cookbook Migration
* Cookbook artifact + all dependent cookbook artifacts stored in Hab Depot.
* Dependency cookbook package manifest:
    ```
    myorigin\role-cookbook
    ∟ myorigin\windows
    ∟ myorigin\upstream-a
    ∟ myorigin\etc...
    ```
* Environment dependency manifest:
    ```
    dev_test_1
    dev_test_2
    qa
    staging
    uat
    prod
    ```
* Data Bag dependency manifest:
    ```
    data_bag_a
    data_bag_b
    ```

### Roles, Environments, Data Bags
1. Obtain list of all nodes + their runlists, roles and environments from Chef Infra Server, for example:
    ```
    node_1:
        ∟ runlist: "cookbook_a::default,cookbook_b::default"
        ∟ environment: "dev"
        ∟ roles: "base,web_frontend"
    node_2:
        ∟ runlist: "cookbook_a::default,cookbook_b::default"
        ∟ environment: "dev"
        ∟ roles: "base,web_frontend"
    node_3:
        ∟ runlist: "cookbook_z::default,cookbook_d::default"
        ∟ environment: "qa"
        ∟ roles: "base,web_backend"
    node_4:
        ∟ runlist: "cookbook_r::default,cookbook_x::default"
        ∟ environment: "prod"
        ∟ roles: "base,redis_cache"
    ```
1. Filter those down to widest group of uniquenes, for example:
    ```
    runlist_1:
        ∟ runlist: "cookbook_a::default,cookbook_b::default"
        ∟ environment: "dev"
        ∟ roles: "base,web_frontend"
        ∟ nodes: "node_1, node_2"
        ∟ count: 2
    runlist_2:
        ∟ runlist: "cookbook_z::default,cookbook_d::default"
        ∟ environment: "qa"
        ∟ roles: "base,web_backend"
        ∟ nodes: "node_3"
        ∟ count: 1
    runlist_3:
        ∟ runlist: "cookbook_r::default,cookbook_x::default"
        ∟ environment: "prod"
        ∟ roles: "base,redis_cache"
        ∟ nodes: "node_4"
        ∟ count: 1
    ```
1. Manual process of naming new unique "policies" (old=>new):
    ```
    runlist_1 => web_frontend
    runlist_2 => web_backend
    runlist_3 => redis_cache
    ```
1. Chef Infra Policy Plan is generated from gathered data, `web_frontend_a` for example:
    ```bash
    # plan.sh
    # This is currently psuedo-code (non-working mock-up)
    pkg_name="web_frontend_a"
    pkg_description="Chef Infra Policy for web_frontend_a"
    pkg_origin="myorigin"
    pkg_version=$(cat "${PLAN_CONTEXT}/../VERSION")
    pkg_maintainer="The Maintainers <humans@yourcompany.com>"
    pkg_license=('Apache-2.0')
    pkg_build_deps=("core/chef-dk")
    pkg_deps=("core/chef-client")
    pkg_scaffolding="chef/policy"

    scaffolding_policy_runlist=("myorigin/cookbook_a, myorigin/cookbook_b")
    scaffolding_policy_environment=("dev")
    ```


### Run List Data





## Comparison Table - Chef Infra Classic to Effortless (Chef Infra Server-less + Hab Managed Chef Infra Client)

|Feature|Chef Infra Classic|Effortless|
|-------|----------|----------|
|**chef-client upgrade**|[Chef Client Updater Cookbook](https://github.com/chef-cookbooks/chef_client_updater)|[chef/chef-client Hab Package](https://bldr.habitat.sh/#/pkgs/chef/chef-client/latest)|
|**Organizations**|[Chef Server Orgs](https://docs.chef.io/server_orgs.html)|[Habitat Origins](https://www.habitat.sh/docs/using-builder/#builder-origin)|
|**Environments**|[Chef Environments](https://docs.chef.io/environments.html)|[Habitat Service Groups](https://www.habitat.sh/docs/using-habitat/#service-groups) will map to Environments using the run hook, for example: `chef-client -E {{svc.group}}`.|
|**Roles**|stored in `*.json`, hosted in Chef Infra Server|*see "Role Cookbooks"|
|**Role Cookbooks**|[Role Cookbook Model](https://github.com/chef-cft/chef-examples/blob/master/examples/RoleCookbookModel.md)|TBD|
|**Data Bags**|stored in `*.json`, hosted in Chef Infra Server|TBD|
|**Environment-level Attributes**|stored in `*.json`, hosted in Chef Infra Server|TBD|
|**Environment Conditionals**|[`case node.chef_environment`](https://stackoverflow.com/questions/19638372/is-it-possible-to-get-current-environment-in-the-attribute-files)|These will continue to work as intended, except they will be tied to the Habitat Service Group that the node is configured to be a part of, the Service Group name will translate into the Environment name.|
|**Knife Commands**|||
||`ssh`|no equivalent + not recommended|
||`search`|[Visibility in Automate](https://automate.chef.io/)|
||`node`|[Visibility in Automate](https://automate.chef.io/)|
||`vault`|we recommend using an application specifically focused on secrets management|
|**Application Orchestration**|Currently a combination of bespoke pipelines, `knife` commands, and other methods to get Chef Infra to converge changes in a specific progression.|Uses Habitat's built-in binding (service contracts), combined with service groups and supervisor rings allow for application lifecycle changes in a controlled, well defined and standardized manner