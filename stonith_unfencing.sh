#! /bin/bash
read -p "pls input stonith disk [sdb]: " sd
a=`ls -l /dev/disk/by-id | grep $sd |awk NR==2'{print $9}'`
pcs stonith create scsi-shooter fence_scsi pcmk_host_list="pcs1 pcs2" devices=/dev/disk/by-id/$a meta provides=unfencing
pcs property set no-quorum-policy=freeze
pcs stonith show scsi-shooter

pcs resource create dlm ocf:pacemaker:controld op monitor interval=30s on-fail=fence clone interleave=true ordered=true

pcs resource create clvmd ocf:heartbeat:clvm op monitor interval=30s on-fail=fence clone interleave=true ordered=true

pcs constraint order start dlm-clone then clvmd-clone
pcs constraint colocation add clvmd-clone with dlm-clone

pcs resource
