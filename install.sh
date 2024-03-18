#!/bin/bash

# Update package repositories
sudo apt update

# Install dependencies
sudo apt install -y build-essential wget curl openssl libssl-dev gcc make

# Create a directory for SoftEther VPN Server installation
mkdir ~/softether-installation
cd ~/softether-installation

# Download SoftEther VPN Server package
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.29-9680-rtm/softether-vpnserver-v4.29-9680-rtm-2019.02.28-linux-x64-64bit.tar.gz
# Extract the downloaded package
tar xzf softether-vpnserver-v4.29-9680-rtm-2019.02.28-linux-x64-64bit.tar.gz

# Move to the extracted directory
cd vpnserver

# Start the installation process
sudo make

# Set permissions for the vpnserver executable
sudo chmod 600 *
sudo chmod 700 vpncmd vpnserver

# Move the vpnserver directory to /usr/local
sudo mv ~/softether-installation/vpnserver /usr/local

# Set up SoftEther VPN as a systemd service
sudo tee /etc/systemd/system/vpnserver.service > /dev/null <<EOF
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
sudo systemctl daemon-reload

# Enable and start the SoftEther VPN Server service
sudo systemctl enable vpnserver
sudo systemctl start vpnserver

# Check the status of the service
sudo systemctl status vpnserver
