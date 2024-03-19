#!/bin/bash

# Update system
apt-get update && apt-get upgrade -y

# Install necessary dependencies
apt-get install -y build-essential net-tools dnsmasq

# Download SoftEther VPN Server
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.39-9772-beta/softether-vpnserver-v4.39-9772-beta-2022.04.26-linux-x64-64bit.tar.gz

# Extract the installer
tar -xvzf softether-vpnserver-v4.39-9772-beta-2022.04.26-linux-x64-64bit.tar.gz

# Move to the extracted directory
cd vpnserver

# Build SoftEther VPN Server
make

# Move vpnserver directory to /usr/local
cd ..
mv vpnserver /usr/local

# Set permissions
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver

# Stop systemd-resolved service
systemctl stop systemd-resolved

# Edit resolved.conf to disable DNSStubListener
echo "DNSStubListener=no" >> /etc/systemd/resolved.conf

# Start systemd-resolved service
systemctl start systemd-resolved

# Edit dnsmasq.conf for DHCP and DNS configuration
echo -e "interface=tap_soft\ndhcp-range=tap_soft,192.168.7.50,192.168.7.60,12h\ndhcp-option=tap_soft,3,192.168.7.1\nserver=1.1.1.1" >> /etc/dnsmasq.conf

# Edit vpnserver startup script
cat <<EOF > /etc/init.d/vpnserver
#!/bin/sh
# BEGIN INIT INFO
# Provides: vpnserver
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start daemon at boot time
# Description: Enable Softether by daemon.
# END INIT INFO
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
TAP_ADDR=192.168.7.1

test -x \$DAEMON || exit 0
case "\$1" in
start)
    \$DAEMON start
    touch \$LOCK
    sleep 1
    /sbin/ifconfig tap_soft \$TAP_ADDR
    ;;
stop)
    \$DAEMON stop
    rm \$LOCK
    ;;
restart)
    \$DAEMON stop
    sleep 3
    \$DAEMON start
    sleep 1
    /sbin/ifconfig tap_soft \$TAP_ADDR
    ;;
*)
    echo "Usage: \$0 {start|stop|restart}"
    exit 1
    ;;
esac
exit 0
EOF

# Set permissions for vpnserver startup script
chmod 755 /etc/init.d/vpnserver

# Update startup script
update-rc.d vpnserver defaults

# Create ipv4 forwarding configuration file
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/ipv4_forwarding.conf

# Apply ipv4 forwarding changes
sysctl --system

# Add rule to firewall
iptables -t nat -A POSTROUTING -s 192.168.7.0/24 -j SNAT --to-source [YOUR_VPS_IP_ADDRESS]

# Install iptables-persistent
apt-get install -y iptables-persistent

# Restart services
/etc/init.d/vpnserver restart
/etc/init.d/dnsmasq restart
