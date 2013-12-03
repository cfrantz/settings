#!/bin/bash
#
# Simple layer-3 VPN using ssh tunnels.
#
# Inspired by https://wiki.archlinux.org/index.php/VPN_over_SSH
#
# You must have the following on your ssh server in sshd_config:
# PermitRootLogin Yes
# PermitTunnel Yes
#
# Local Configuration:
# N is the tunnel instance.  This must be unique among all tunnel users
# L is the local tunnel instance.  Leave this as zero unless you're running
#   multiple tunnels from your client.
# USER is the user to log into the server
# SERVER is the server hosting the tunnels
# DESTNET/DESTMASK refer to the destination network
# LINKNET is the network prefix for building the point-to-point links

if [ `whoami` != "root" ]
then
    sudo $0 $*
    exit $?
fi

N=0
L=0
USER=root
SERVER=${1:-my-gateway}
DESTNET=172.30.0.0
DESTMASK=255.255.0.0

LINKNET=172.30.255
LINKMASK=255.255.255.252
DNS=$(cat <<EOT
# Tunnel DNS configuration
nameserver 172.30.0.1
EOT
)

### Compute needed values

LADDR=$LINKNET.$((N*4+1))
RADDR=$LINKNET.$((N*4+2))
T=tun$N

### Connect to server, establish tunnels
ssh \
    -o PermitLocalCommand=yes \
    -o LocalCommand="ifconfig tun$L $LADDR pointopoint $RADDR netmask $LINKMASK; route add -net $DESTNET netmask $DESTMASK gw $RADDR; cp /etc/resolv.conf /etc/resolv.conf.tunnel; echo \"$DNS\" >/etc/resolv.conf" \
    -o ServerAliveInterval=60 \
    -w $L:$N $USER@$SERVER \
    "ifconfig $T $RADDR pointopoint $LADDR netmask $LINKMASK; echo Tunnel Ready"

echo "Tunnel Closed"
cp /etc/resolv.conf.tunnel /etc/resolv.conf
# vim: ts=4 sts=4 sw=4 expandtab:
