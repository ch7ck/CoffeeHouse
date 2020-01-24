#Debugging Mounted Raspbian SD Card

Let's suppose that you need to evaluate a Raspberry Pi micro-sd card that is powered off.  

In theory you could `lsblk` or `fdisk -l` every single time to see what your device name is but it leaves you having to mount the drive by hand every single time you insert the micro-sd card adapter to your workstation.  Rather than having mount your drive manually you should create a systemd-automount service.  More information can be found by inspecting the man page `man systemd.automount`

##Find out Hardware ID of Micro-SD card:
To become sudo on your Debian, Ubuntu, or Raspbian box while keeping your ENV use:

    username@hostname:~$ sudo -Es


    root@hostname:~$ 'watch -n 2 blkid | tail -n 3'


Now insert your micro-sd card adapter into your workstation.

If you had previously formatted your micro-sd card with say raspbian you should have two lines /dev/sdX1 (the boot partition) and /dev/sdX2 (the rootfs partition).  In order to automount these partitions you will need their UUID (note that both PARTUUIDs are the same).  

![image](https://user-images.githubusercontent.com/7351154/73054258-d32c1f00-3e3e-11ea-91dc-ca47bb8e693d.png)

Now open up /etc/fstab with your text editor and create a line that will mount your partition at say /mnt/pirootfs like so:

    root@hostname:~# cat >> /etc/fstab << EOF
    UUID=2ab3f8e1-7dc6-43f5-b0db-dd5759d51d4e /mnt/pirootfs/      ext4    auto,nofail
    EOF

Now is where we have to "reload" the systemd daemons by issuing:

    root@hostname:~# systemctl daemon-reload

We can see that /etc/fstab rules that systemd creates have been reloaded and generated a new unit file for this mount point by viewing the new file:

    root@hostname:~# view /run/systemd/generator/mnt-pirootfs.mount

![image](https://user-images.githubusercontent.com/7351154/73054840-42564300-3e40-11ea-83f7-87209e17652a.png)


It's worth noting that the naming convention for mount points and automount points is:

`directory-subdirectory-moresubdirectory.mount`  

`directory-subdirectory-moresubdirectory.automount`  

So if you were making this mount point directory for the first time you would issue:

    root@hostname:~# mkdir -pv /directory/subdirectory/moresubdirectory


With the auto-generated `mnt-pirootfs.mount` we can now create an automount systemd unit file mentioned in `man systemd.automount`:

    root@hostname:~# cat > /etc/systemd/system/mnt-pirootfs.automount << EOF
    [Unit]
    Description=Automount Raspberry Pi micro-sd card

    [Automount]
    Where=/mnt/pirootfs
    [Install]
    WantedBy=multi-user.target
    EOF

Now view the status:

    root@hostname:~# systemctl status mnt-pirootfs.automount

![image](https://user-images.githubusercontent.com/7351154/73056027-e640ee00-3e42-11ea-8902-08eff8400682.png)

Now we will enable the unit file (notice how it creates a symlink).

    root@hostname:~# systemctl enable mnt-pirootfs.automount

![image](https://user-images.githubusercontent.com/7351154/73056130-1ee0c780-3e43-11ea-98eb-940abb8f7e76.png)

Even though the service is now enabled for future reboots we still need to start up the service.

    root@hostname:~# systemctl start mnt-pirootfs.automount


Now a different status response should appear with a green dot showing that the service is currently "active":

    root@hostname:~# systemctl status mnt-pirootfs.automount

![image](https://user-images.githubusercontent.com/7351154/73056296-8e56b700-3e43-11ea-8791-6c562ecf21d4.png)

For the automount to kick in we simply need to cd into the directory of our automount partition:

    root@hostname:~# cd /mnt/pirootfs/

If you run something like an `ls` you can now see that you're able to view the root file-system without having to mount manually each time (just simply go to a mount point you created)



To get more information about systemd automounting:

```man systemd.automount```

## TODO
    [x] Basic Usage
    [ ] More documentation
    [ ] More information regarding 
