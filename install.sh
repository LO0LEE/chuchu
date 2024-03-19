#!/bin/bash

# Update and upgrade the system
apt-get update
apt-get upgrade -y

# Install necessary dependencies
apt-get install -y build-essential net-tools

# Download the latest version of SoftEther VPN Server
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.39-9772-beta/softether-vpnserver-v4.39-9772-beta-2022.04.26-linux-x64-64bit.tar.gz

# Extract the installer
tar -xvzf softether-vpnserver-v4.39-9772-beta-2022.04.26-linux-x64-64bit.tar.gz

# Navigate to the extracted directory and install SoftEther
cd vpnserver
make

# Move the extracted directory to /usr/local
cd ..
mv vpnserver /usr/local

# Set permissions
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver

# Test SoftEther VPN Server operation
./vpncmd <<EOF
3
check
exit
EOF

# Create a systemd service file
cat <<EOF > /etc/systemd/system/vpnserver.service
[Unit]
Description=SoftEther VPN Server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
ExecStartPost=/bin/sleep 3
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply changes
systemctl daemon-reload

# Enable and start the SoftEther VPN Server service
systemctl enable vpnserver
systemctl start vpnserver
