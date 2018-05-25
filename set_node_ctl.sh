#!/bin/bash

#set_node_ctl
ipnum=$(ip a|grep '10.2.'|awk '{print$2}'|cut -d'.' -f4|cut -d'/' -f1)

##bond interface
sed -i '/^auto enp6s0f0/,+2d' /etc/network/interfaces 
sed -i '/^auto enp8s0f0/,+2d' /etc/network/interfaces
##modify interfaces file
cat >>/etc/network/interfaces <<EOF
auto enp6s0f0
iface enp6s0f0 inet manual
    bond-master bond1
    
auto enp8s0f0
iface enp8s0f0 inet manual
    bond-master bond1 

auto bond1
iface bond1 inet manual
    mtu 1500
    bond-ad_select 0
    bond-downdelay 200
    bond-lacp_rate 0
    bond-miimon 100
    bond-mode 4
    bond-slaves enp6s0f0 enp8s0f0
    bond-updelay 0
    bond-use_carrier on

auto bond1.31
iface bond1.31 inet manual

auto br_ctl
iface br_ctl inet static
    address 192.168.11.${ipnum}
    netmask 255.255.252.0
    dns-nameservers 223.5.5.5 114.114.114.114 
    bridge_ports bond1.31   
EOF

brctl addbr br_ctl
ifdown enp8s0f0
ifdown enp6s0f0
ifup enp6s0f0
ifup enp8s0f0
##waiting network 
sleep 10

##node vms add interfaces
for i in $(virsh list|sed '1,2d'|awk '{print$2}'|sed '$d');do 
virsh attach-interface --domain ${i} --type bridge --source br_ctl --model virtio --live --persistent;
done
