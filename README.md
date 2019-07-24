# migration-upgrade

Tool for Chef 15 upgrade and Effortless migration


## Steps
- Fetch all nodes from server
- Create a list of unique run lists
- If any of those run_list combos have a node on the server running Chef 15+ then skip it since we know it works on a modern Infra Client
- For each run list combination download all the cookbooks in that run list from the server into unique directories on the local host
- Run cookstyle / foodcritic against those directories alerting on just the deprecation rules. Create a report of code changes that will need to be made per run list combination
