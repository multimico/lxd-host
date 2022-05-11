#!/bin/bash

BINDIR=$( dirname "$(readlink -f "${BASH_SOURCE}")" )
DATADIR="$( dirname ${BINDIR} )/data"
MACADDRESS=$1

PACKAGES=$(yq ".packages[]" ${DATADIR}/init.yaml)
apt install -y $PACKAGES

### 
# Speedup Grub
# Fix the timeout for modern EFI Systems

sed -i -e "/^GRUB_TIMEOUT=/a GRUB_RECORDFAIL_TIMEOUT=1" /etc/default/grub

upgrade-grub

### 
# OVS and Network setup 

# add bridging switch ovs0 
ovs-vsctl add-br ovs0

# create  host interface mgnt0 and add it to switch ovs0
ovs-vsctl add-port ovs0 mgnt0 -- set interface mgnt0 type=internal

# add phys hardware (eno1) to switch ovs0
ovs-vsctl add-port ovs0 eno1

# At this point the mgnt0 device should be able to receive an IP address

# fix netplan
sed -i -e "s/dhcp4: true/dhcp4: no/"  -e "/^  version: 2/i \\ \\ \\ \\ mgnt0:\\n\\ \\ \\ \\ \\ \\ dhcp4: true\\n\\ \\ \\ \\ \\ \\ macaddress: $MACADDRESS" /etc/netplan/00-installer-config.yaml
# activate new netplan configuration
netplan apply

### 
# Init lxd
cp ${DATADIR}/preseed.yaml /etc/lxd/preseed.yaml
cat /etc/lxd/preseed.yaml | lxd init --preseed

echo "Succeeded"

if [ -f -f /var/run/reboot-required ]
then
    reboot
fi