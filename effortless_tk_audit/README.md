# Effortless Audit Test-Kitchen exaple.

This pattern is being used to support development on a local workstation when restrictions are in place that prevent installation of all tools required.
This particular package will load Centos 7 and audit settings on various controls


**This repo will demo the following**
* The stucture of an effortless audit packahge
* How to use scaffolding in your plan.sh
* How to build an effortless audit package within a Test-Kitchen instance.

### To run the demo do the following.
1. Set HAB_ORIGIN in your terminal `export HAB_ORIGIN=origin_name` (Skipping this will cause the run to fail)
2. Edit plan.sh to match and add your origin.
3. Add origin to bootstrap.sh
4. Run `kitchen converge`
5. Run `kitchen verify`
6. Profit..

