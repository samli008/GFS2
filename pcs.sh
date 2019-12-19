echo "choise 1 to install pcs packages on all nodes."
echo "choise 2 to config pcs cluster only one node."
echo "choise 3 to config stonith dlm clvmd only one node."
echo "choise 4 to config vip."
read -p "pls input your choise [1]: " n

case $n in
1)
yum -y install pcs fence-agents-all lvm2-cluster gfs2-utils
systemctl enable pcsd
systemctl start pcsd
echo "liyang" | passwd --stdin hacluster
lvmconf --enable-cluster
lvmconf -h
lvmconfig |grep type
echo "pls reboot host for clvm."
;;

2)
read -p "pls intput node1 hostname: " pcs1
read -p "pls intput node2 hostname: " pcs2
read -p "pls intput cluster name: " name
pcs cluster auth $pcs1 $pcs2 -u hacluster -p liyang
pcs cluster setup --name $name $pcs1 $pcs2
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=true

pcs status cluster

;;

3)
read -p "pls intput node1 hostname: " pcs1
read -p "pls intput node2 hostname: " pcs2
read -p "pls input stonith disk [sdb]: " sd
a=`ls -l /dev/disk/by-id | grep $sd |awk NR==2'{print $9}'`
pcs stonith create scsi-shooter fence_scsi pcmk_host_list="$pcs1 $pcs2" devices=/dev/disk/by-id/$a meta provides=unfencing
pcs property set no-quorum-policy=freeze
pcs stonith show scsi-shooter

pcs resource create dlm ocf:pacemaker:controld op monitor interval=30s on-fail=fence clone interleave=true ordered=true

pcs resource create clvmd ocf:heartbeat:clvm op monitor interval=30s on-fail=fence clone interleave=true ordered=true

pcs constraint order start dlm-clone then clvmd-clone
pcs constraint colocation add clvmd-clone with dlm-clone

pcs resource
echo "pls use below cli create clvm gfs2 on share volume."
echo "mkfs.gfs2 -j 2 -p lock_dlm -t cluster1:gfs1 /dev/vg1/lv1"
;;

4)
read -p "pls input vip[192.168.20.188]: " vip
pcs resource create vip ocf:heartbeat:IPaddr2 ip=$vip cidr_netmask=24 op monitor interval=30s
;;

*)
echo "pls input 1-4 choise."
exit;

esac
