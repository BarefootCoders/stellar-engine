#!/bin/bash
#Update and install necessary packages
echo "Hello, world step 1" > /var/log/startup-script.log
apt-get update
apt-get install -y curl wget

# Download and install Security Onion
wget https://download.securityonion.net/file/securityonion/securityonion-2.3.300-20240401.iso -O /tmp/securityonion.iso
# https://download.securityonion.net/file/securityonion/securityonion-2.3.300-20240401.iso
# https://github.com/Security-Onion-Solutions/securityonion/blob/master/VERIFY_ISO.md
mkdir -p /mnt/so-iso
mount -o loop /tmp/securityonion.iso /mnt/so-iso

# Install necessary dependencies
apt-get install -y squashfs-tools
unsquashfs -d /tmp/so-extracted /mnt/so-iso/casper/filesystem.squashfs

# Run the Security Onion installer
/tmp/so-extracted/usr/sbin/securityonion-setup -y

# Add your custom Security Onion setup commands here
# ...

# Clean up
umount /mnt/so-iso
rm -rf /tmp/securityonion.iso /tmp/so-extracted
echo "Security Onion installation complete!" > /var/log/startup-script.log
# Add your custom startup commands here

