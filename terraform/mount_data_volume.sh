#!/bin/bash -ex

# format and mount the /hab volume
mkdir -p /hab
pvs | grep nvme1n1 || pvcreate /dev/nvme1n1
vgs | grep data-vg || vgcreate data-vg /dev/nvme1n1
lvs | grep data-lv || (lvcreate -n data-lv -l 95%VG data-vg ; mkfs.xfs /dev/data-vg/data-lv)
grep hab /proc/mounts || mount /dev/data-vg/data-lv /hab
grep 'data--vg-data--lv' /etc/fstab || echo '/dev/mapper/data--vg-data--lv /hab xfs defaults 0 0' >> /etc/fstab
