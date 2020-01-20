# Exploring Systemd with your RaspberryPi 

For some reason or another I would get stuck in this cyclical situation where I just couldn't even see what was wrong with the RaspberryPi (sometimes it turned out to be fsck taking too long).  

Other times assigning a static IP address turned into a much longer affair than needed.  It such a time waster when you just want to get up and running...The best or worst is using nmap to scan for the pi (`arp-scan` worked well if it was on the system). 

The reason that this exists is because there have been times when I just wanted the RaspberryPi to work and Google, DDG, and Bing just led to stack overflows which to me felt really out of date or lacked context.  

Raspberry Pi's are such a powerful tool if you don't get bogged down  by rabbit holing some strange issue wherein there are too many gotchas.  I've tried my best to compile a few minimal script(s) that will get anyone with an micro-sd card up and running so the first time you power on the Pi just works.

It's worth noting that none of this came about by going at it on my own most of my A-ha's came from reading the [Arch Systemd-networkd Wiki](https://wiki.archlinux.org/index.php/Systemd-networkd) and stumbling upon that golden forum post. 


RaspberryPi's are the prototypers go-to.  We're going to step through a few simple things you can do to get up and running so you can ssh into it.  This specific walkthrough will step you through:
  
- Downloading Debian Buster
- Writing the .img to a micro-sd card
- Creating an SSH Key-Pair
- Tackle Networking through systemd
- Start Your Business and.........Profit!


# De-generate your SSH Key-Pair
    username@hostname:~$ ssh-keygen -t rsa -b 4096 -f paranoid_rsa -C YourLatestKey
    ------Flag Play by Play:
    RTFM
    
# Download Raspbian.
Head over to the [RaspberryPi Downloads page](https://www.raspberrypi.org/downloads/raspbian/) to grab the sha_sum of the raspbian-lite zipped image.

The torrent is faster.  If you feel so inclined seed.

At the time of this post the current sha256sum is `a50237c2f718bd8d806b96df5b9d2174ce8b789eda1f03434ed2213bbca6c6ff`.

    wget https://downloads.raspberrypi.org/raspbian_lite_latest && \
    sha256sum raspbian_lite_latest | grep a50237c2f718bd8d806b96df5b9d2174ce8b789eda1f03434ed2213bbca6c6ff || \
    echo "ShaSum not correct...."

If you didn't get the "ShaSum not correct response you will want to now unzip your "verified" zipped file 

    username@hostname:~$ unzip raspbian_lite_latest
    
# Write the image to your MicroSD Card

After inserting your microsd card through a usb drive or micro-sd converter (as pictured) you will want to find the name of your drive.  You've got some options.  I prefer `lsblk` but that's just one of the many ways to skin the proverbial cat.  Other ways include:

 `sudo fdisk -l`
 `systemd-mount --list`
 
 If you really feel like monitoring exactly what is happening run either of these commands when you insert the medium:
 `sudo udisksctl monitor`
 `iostat -t 1`
 A new device should appear.  In my case the device name was `/dev/sdc` 
 
 When unzipping the downloaded image I am presented with the inflated file `2019-09-26-raspbian-buster-lite.img`.  Use this filename by passing it to the if= flag of the `dd` command the new device name will be followed by the of= flag.  To finally get down to business and write the raspbian image to the micro-sd card.
 
    username@hostname:~$ sudo dd if=2019-09-26-raspbian-buster-lite.img of=/dev/sdc bs=4MB status=progress

Once completed we can now get to the business of actually getting some things up and running.......well almost

# Getting access to the RaspberryPi....

Before we can boot up the Pi and SSH into it we must first mount the 2nd partition of the device and add our newly created SSH public key.

    username@hostname:~$ mkdir -v pirootfs
    
At this point I'm getting a bit sick of having to type sudo over and over again.  To stop this madness I suggest logging in as root (be careful, dragons be here.....or here be dragons)

    username@hostname:~$ sudo -Es
    root@hostname:~# mount /dev/sdc2 pirootfs/
    root@hostname:~# cd pirootfs/home/pi
    root@hostname:~# mkdir -v pirootfs/home/pi/.ssh
    root@hostname:~# cat paranoid_rsa.pub > pirootfs/home/pi/.ssh/authorized_keys

# Working With Systemd
Now that we're going on all cylinders let's start to look under the hood of systemd.  If you're not familiar with systemd you need not worry, it can do pretty much anything your heart desires.  The biggest take away from what we are going to be doing is explained in the [systemd.units man page examples](https://manpages.debian.org/buster/systemd/systemd.unit.5.en.html#EXAMPLES):

- Enabling runtime services such as `ssh.service` and `systemd-networkd.service`  
- Disabling runtime services symlinks which point to `/dev/null`

This is of course a very simplistic way of viewing what we'll be addressing...In my opinion it's much easier to manage services, sockets, networking, and mount points under the systemd way of doing things rather than init's...best to RTFM for further details on exactly how systemd's service files work.  `man systemd.units`



### Systemd-networkd Configuration

Since we're going to be dealing with networking directly with systemd it's important to address all the peices fitting together.  Namely

Interfaces (setting up systemd-networkd interfaces)
DNS (setting up systemd-resolved)
WPA-Supplicant (creating wpa_supplicant interface file and creating service)
DHCPD (disable)

A lot of what I'm doing is touched on in https://wiki.debian.org/SystemdNetworkd

First I'm going to mv the /etc/network/interfaces file on the 2nd partition of the pi's micro-sd card:

    root@hostname:~# mv -v pirootfs/etc/network/interfaces pirootfs/etc/network/interfaces.save

now we are going to create a symlink for systemd-networkd to "Enable"  the service by creating a few symlinks:

    root@hostname:~# ln -sv pirootfs/lib/systemd/system/systemd-networkd.service pirootfs/etc/systemd/system/dbus-org.freedesktop.network1.service
    root@hostname:~# ln -sv pirootfs/lib/systemd/system/systemd-networkd.service pirootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service
    root@hostname:~# ln -sv pirootfs/lib/systemd/system/systemd-networkd.socket pirootfs/etc/systemd/system/sockets.target.wants/systemd-networkd.socket
    root@hostname:~# ln -sv pirootfs/etc/systemd/system/systemd-networkd-wait-online.service pirootfs/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service

Now we enable systemd-resolved:

    root@hostname:~# ln -sv pirootfs/lib/systemd/system/systemd-resolved.service pirootfs/etc/systemd/system/dbus-org.freedesktop.resolve1.service
    root@hostname:~# ln -sv pirootfs/lib/systemd/system/systemd-resolved.service pirootfs/etc/systemd/system/multi-user.target.wants/systemd-resolved.service

Now create a symlink for resolv.conf:

    root@hostname:~# ln -svf /run/systemd/resolve/resolv.conf /etc/resolv.conf

We also want   to add this to resolvconf.conf more:

    # cat >> pirootfs/etc/resolvconf.conf << "EOF"
    > # Set to NO to disable resolvconf from running any subscribers. Defaults to YES.
    > resolvconf=NO
    > EOF
    
Now we address the old Debian networking stuff that could get in our way by masking "creating /dev/null symlinks" to services we don't want getting in our way like dhcpcd and the  networking service:

    root@hostname:~# ln -svf /dev/null pirootfs/etc/systemd/system/multi-user.target.wants/networking.service
    root@hostname:~# ln -svf /dev/null pirootfs/etc/systemd/system/network-online.target.wants/networking.service
    root@hostname:~# ln -svf /dev/null  pirootfs/etc/systemd/system/dhcpcd.service

To enable  wireless for our  access point  do the following (first masking  the regular wpa_supplicant.service and enabling the interfaces wpa_supplicant service)

    root@hostname:~# ln -svf /dev/null pirootfs/etc/systemd/system/wpa_supplicant.service

    root@hostname:~# ln -sv pirootfs//lib/systemd/system/wpa_supplicant@.service pirootfs/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
