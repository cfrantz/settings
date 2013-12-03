#!/bin/bash
#
# Simple layer-2 VPN using ssh tunnels.
#
# Inspired by https://wiki.archlinux.org/index.php/VPN_over_SSH
#             http://la11111.wordpress.com/2012/09/24/layer-2-vpns-using-ssh/
#
# You must have the following on your ssh server in sshd_config:
# PermitRootLogin Yes
# PermitTunnel Yes
#
# You also need a bridge on your server and some preconfigured tap/tun
# interfaces
#
# e.g. /etc/network/interfaces for ubuntu:
#
#   auto eth2
#   iface eth2 inet static
#       address 0.0.0.0
#
#   auto devnet
#   iface devnet inet dhcp
#       bridge_ports eth2
#
#   auto tap0
#   iface tap0 inet static
#       pre-up tunctl -b -u root -t tap0
#       address 0.0.0.0
#
# Local Configuration:
# N is the tunnel instance.  This must be unique among all tunnel users
# L is the local tunnel instance.  Leave this as zero unless you're running
#   multiple tunnels from your client.
# USER is the user to log into the server
# SERVER is the server hosting the tunnels
# DESTNET/DESTMASK refer to the destination network
if [ `whoami` != "root" ]
then
    exec sudo $0 $*
    exit 0
fi

N=0
L=1
USER=root
SERVER=${1:-vsr19-bridge}
BRIDGE=devnet
DESTNET=172.17.0.0
DESTMASK=255.255.0.0

### Compute needed values
T=tap$N

### Connect to server, establish tunnels
ssh \
    -o PermitLocalCommand=yes \
    -o Tunnel=ethernet \
    -o LocalCommand="cp /etc/resolv.conf /etc/resolv.conf.tunnel; dhclient -nw -pf /run/dhclient.tap$L.pid tap$L" \
    -w $L:$N $USER@$SERVER \
    "ifconfig $T up; (brctl show $BRIDGE | grep -q $T) || brctl addif $BRIDGE $T; echo Tunnel Ready"

echo "Tunnel Closed"
kill `cat /run/dhclient.tap$L.pid`
cp /etc/resolv.conf.tunnel /etc/resolv.conf
# vim: ts=4 sts=4 sw=4 expandtab:
