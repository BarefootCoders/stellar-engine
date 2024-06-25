#!/bin/bash
# Update package list and install necessary packages
sudo apt-get update
sudo apt-get install -y software-properties-common

# Install Security Onion
sudo add-apt-repository -y ppa:securityonion/stable
sudo apt-get update
sudo apt-get install -y securityonion-all

# Start Security Onion setup (note: this is interactive; adjust as needed)
sudo sosetup
