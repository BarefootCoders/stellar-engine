#!/bin/bash
#Update and install necessary packages
sudo yum update
echo "Step 1 yum update" > /var/log/startup-script.log

sudo yum -y install git
echo "Step 2 Install Git" > /var/log/startup-script.log
git clone https://github.com/Security-Onion-Solutions/securityonion
cd securityonion
#sudo bash so-setup-network
echo "Step 3 Git Clone" > /var/log/startup-script.log