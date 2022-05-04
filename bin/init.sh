#!/bin/bash
Packages=$(yq ".packages[]" data/init.yaml)
apt install -y $Packages

cp data/preseed.yaml /etc/lxd/preseed.yaml

ovs-vsctl add-br ovs0
ovs-vsctl add-port ovs0 mgnt0 -- set interface mgnt0 type=internal
# fix netplan
sed -i -e "s/dhcp4: true/dhcp4: no/"  -e "/^  version: 2/i \\ \\ \\ \\ mgnt0:\\n\\ \\ \\ \\ \\ \\ dhcp4: true" /etc/netplan/00-installer-config.yaml
netplan apply
# activate phys hardware
ovs-vsctl add-port ovs0 eno1
# Init lxd
cat /etc/lxd/preseed.yaml | lxd init --preseed

echo "Succeeded"