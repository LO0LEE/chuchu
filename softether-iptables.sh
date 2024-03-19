#!/bin/sh

##########################################################################################################################################
### Configuration
#############################

TAP_ADDR=192.168.30.1         # Main IP of your TAP interface
TAP_INTERFACE=tap_soft        # The name of your TAP interface.
VPN_SUBNET=192.168.30.0/24    # Virtual IP subnet you want to use within your VPN
YOUREXTERNALIP=$(hostname -I | cut -d ' ' -f 1)   # Your machine's external IPv4 address

#############################
### End of Configuration
##########################################################################################################################################

# Flush Current rules
iptables -F && iptables -X

# Assign $TAP_ADDR to our tap interface
/sbin/ifconfig $TAP_INTERFACE $TAP_ADDR

# Forward all VPN traffic that comes from VPN_SUBNET through $NET_INTERFACE interface for outgoing packets.
iptables -t nat -A POSTROUTING -s $VPN_SUBNET -j SNAT --to-source $YOUREXTERNALIP

# Allow VPN Interface to access the whole world, back and forth.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
iptables -A OUTPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
iptables -A FORWARD -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
