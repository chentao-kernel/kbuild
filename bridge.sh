#!/bin/bash

sudo brctl addbr br0

sudo apt install -y uml-utilities
sudo tunctl -t tap0 -u root
sudo brctl addif br0 tap0

#/etc/netplan/50-cloud-init.yaml
#network:
#    ethernets:
#        br0:
#            dhcp4: true
#    version: 2


#network:
#    version: 2
#    ethernets:
#        eth0:  # 替换为实际的物理接口名称
#            dhcp4: no
#    bridges:
#        br0:
#            dhcp4: true
#            interfaces:
#                - eth0

sudo ifconfig br0 0.0.0.0 promisc up
sudo ifconfig ens33 0.0.0.0 promisc up
