# CoffeeHouse

RaspberryPi's are the prototypers swiss-army knife.  This repo aims to make getting them up and running quickly.
  
- [x] Create SSH Key-Pair
- [x] Downloading Raspbian
- [x] HotSpot with `systemd-networkd` + `wpa_supplicant`

## Getting Started

Right now bash variables need to be set:
 
`MICROSDDEVICE=` in both [get_raspbian.sh](get_raspbian.sh) and [setup_pi_script.sh](setup_pi_script.sh)


Set the scripts as executable:

    chmod +x get_raspbian.sh
    chmod +x setup_pi_script.sh

Run the executable to download and write the raspbian image:
    
    ./get_raspbian.sh


Make sure get_raspbian has successfully downloaded and been `dd`'d to your micro-sd card.

    ./setup_pi_script.sh


Once you have run this (and hopefully it didn't exit mid run :crossed_fingers: you should be able to eject the `MICROSDDEVICE` and boot up your pi!

You should see a "coffeeshop" wifi-network.  Connect to that and you can now ssh to your raspberry pi

## TODO

- [ ] Better Documentation!
- [ ] Add Unit Test(s)
- [ ] Add CI build Test

Document Link | Topic
--------------| -------
[Overall Command Walkthrough](walkthrough.md) | Full explanation of commands in [get_raspbian.sh](get_raspbian.sh) and [setup_pi_script.sh](setup_pi_script.sh)


## Pull Requests
Please feel free to fork and submit pull requests!  If you have a feature request feel free to open up an issue.

If you decide to write something run it through `aspell -c filename`.  

> The only true wisdom is in knowing you know nothing
> Socrates
