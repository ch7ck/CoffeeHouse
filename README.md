# CoffeeHouse

RaspberryPi's are the prototypers swiss-army knife.  This repo aims to make getting them up and running quickly.
  
[x] Create SSH Key-Pair
[x] Downloading Raspbian
[x] HotSpot with `systemd-networkd` + `wap_supplicant`

## Getting Started

Right now bash variables need to be set:
 
`MICROSDDEVICE=` in both [get_raspian.sh](get_raspian.sh) and [setup_pi_script.sh](setup_pi_script.sh)


Set the scripts as executable:

    chmod +x get_raspian.sh
    chmod +x setup_pi_script.sh

Run the executable to download and write the raspbian image:
    
    ./get_raspian.sh


Make sure get_raspian has successfully downloaded and been `dd`'d to your micro-sd card.

    ./setup_pi_script.sh


Once you have run this (and hopefully it didn't exit mid run :crossed_fingers: you should be able to eject the `MICROSDDEVICE` and boot up your pi!

You should see a "coffeeshop" wifi-network.  Connect to that and you can now ssh to your raspberry pi

## Pull Requests
Please feel free to fork and submit pull requests!  If you have a feature request feel free to open up an issue.

> The only true wisdom is in knowing you know nothing
> Socrates
