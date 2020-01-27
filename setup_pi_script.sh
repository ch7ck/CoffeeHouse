#!/bin/bash

# Exit script if a non-zero exit code
set -e

uname -a | grep Linux || ( echo "not on a linux box, lets stop here" && exit -1 ) 


# You need to set this once you have found the device name `lsblk`
MICROSDDEVICE=$1 # /dev/sd?

if [[ ! -d ${PWD}/pibootpartition ]]; then
    mkdir -v ${PWD}/pibootpartition
fi

if [[ ! -d ${PWD}/pirootfs ]]; then
    mkdir -v ${PWD}/pirootfs
fi

mount -v ${MICROSDDEVICE}1 ${PWD}/pibootpartition
mount -v ${MICROSDDEVICE}2 ${PWD}/pirootfs

FULLPIROOTPATH=${PWD}/pirootfs

touch ${PWD}/pibootpartition/ssh

function enable_camera() {

cat >> ${PWD}/pibootpartition/config.txt << "EOF"
start_x=1
gpu_mem=128
disable_camera_led=1
EOF

};



# Create ssh key pair

ssh-keygen -t rsa -b 4096 -f ${PWD}/paranoid_rsa -C Paranoid?

mkdir -v ${FULLPIROOTPATH}/home/pi/.ssh/
cat ${PWD}/paranoid_rsa.pub > ${FULLPIROOTPATH}/home/pi/.ssh/authorized_keys

# Change what normally brings up the interfaces
mv -v ${FULLPIROOTPATH}/etc/network/interfaces ${FULLPIROOTPATH}/etc/network/interfaces.save

# Get systemd-networkd enabled through symlinks!

ln -sv ${FULLPIROOTPATH}/lib/systemd/system/systemd-networkd.service ${FULLPIROOTPATH}/etc/systemd/system/dbus-org.freedesktop.network1.service
ln -sv ${FULLPIROOTPATH}/lib/systemd/system/systemd-networkd.service ${FULLPIROOTPATH}/etc/systemd/system/multi-user.target.wants/systemd-networkd.service
ln -sv ${FULLPIROOTPATH}/lib/systemd/system/systemd-networkd.socket ${FULLPIROOTPATH}/etc/systemd/system/sockets.target.wants/systemd-networkd.socket
ln -sv ${FULLPIROOTPATH}/etc/systemd/system/systemd-networkd-wait-online.service ${FULLPIROOTPATH}/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service


# create systemd-networkd .network and wpa_supplicant files

cat > ${FULLPIROOTPATH}/etc/systemd/network/08-wifi-ap.network << EOF
[Match]
Name=wl*

[Network]
#LinkLocalAddressing=no
Address=10.0.0.1/24
DHCPServer=yes
IPForward=ipv4
IPMasquerade=yes

[DHCPServer]
DNS=8.8.8.8 8.8.4.4
EOF

# Set this if you'd like to have a static IP set on your network

STATICIP="192.168.*.*"

cat > ${FULLPIROOTPATH}/etc/systemd/network/04-eth.network << EOF
[Match]
Name=e*
[Network]
# to use static IP (with your settings) toggle commenting the next 8 lines.
#Address=${STATICIP}
#DNS=84.200.69.80 1.1.1.1
#[Route]
#Gateway=192.168.50.1
#Metric=10
DHCP=yes
[DHCP]
RouteMetric=10
EOF

# Now for wpa_supplicant-wlan0.conf 

# Set a random-ish passcode for the hotspot network
HOTSPOTKEY=$(date +%s | sha256sum | base64 | head -c 8; echo)
cat > ${FULLPIROOTPATH}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf << EOF
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="coffeeshop"
    mode=2
    key_mgmt=WPA-PSK
    proto=WPA 
    psk="${HOTSPOTKEY}" 
}
EOF

# Mask regular wpa_supplicant and setup interface specific wpa_supplicant

ln -svf /dev/null ${FULLPIROOTPATH}/etc/systemd/system/wpa_supplicant.service

# The wpa_supplicant-wlan0.conf must match your interface name

ln -sv ${FULLPIROOTPATH}//lib/systemd/system/wpa_supplicant@.service ${FULLPIROOTPATH}/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service


# Get systemd-resolved enabled through symlinks
ln -sv ${FULLPIROOTPATH}/lib/systemd/system/systemd-resolved.service ${FULLPIROOTPATH}/etc/systemd/system/dbus-org.freedesktop.resolve1.service
ln -sv ${FULLPIROOTPATH}/lib/systemd/system/systemd-resolved.service ${FULLPIROOTPATH}/etc/systemd/system/multi-user.target.wants/systemd-resolved.service

# set resolv.conf symlink for systemd-resolved more information can be found at man systemd-resolved
ln -svf /run/systemd/resolve/resolv.conf ${FULLPIROOTPATH}/etc/resolv.conf

cat >> ${FULLPIROOTPATH}/etc/resolvconf.conf << "EOF"
# Set to NO to disable resolvconf from running any subscribers. Defaults to YES.
resolvconf=NO
EOF

# Mask / disable debian networking defaults networking.service and dhcpcd.service

ln -svf /dev/null ${FULLPIROOTPATH}/etc/systemd/system/multi-user.target.wants/networking.service
ln -svf /dev/null ${FULLPIROOTPATH}/etc/systemd/system/network-online.target.wants/networking.service
ln -svf /dev/null  ${FULLPIROOTPATH}/etc/systemd/system/dhcpcd.service


printf "\n\n\nIf you made it this far things should hopefully being going well\n\n\n"

cat > paranoid_ssh_config << EOF
Host RaspiHotspot
    Hostname 10.0.0.1
    Port 22
    User pi
    ServerAliveInterval 200
    IdentitiesOnly yes
    IdentityFile paranoid_rsa
    UserKnownHostsFile /dev/null 
    StrictHostKeyChecking no
EOF

printf "\nTo SSH INTO THE PI CONNECT TO THE coffeeshop wifinetwork then use the paranoid_ssh_config file\n\n"

printf "DO THIS:\n\nssh -F paranoid_ssh_config RaspiHotspot\n\n"

enable_camera
