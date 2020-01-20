#!/bin/bash

MICROSDDEVICE="" # /dev/sd?
RASPIANSHA256="a50237c2f718bd8d806b96df5b9d2174ce8b789eda1f03434ed2213bbca6c6ff" # NEEDS
# Exit script if a non-zero exit code
set -e


uname -a | grep Linux || ( echo "not on a linux box, lets stop here" && exit -1 ) 

# Get raspbian 

curl -L -o "raspbian.zip" --url "https://downloads.raspberrypi.org/raspbian_lite_latest"

sha256sum raspbian.zip | grep ${RASPIANSHA256} || \
 ( echo "ShaSum not correct...." && exit )

unzip raspbian.zip

IMGNAME=$(ls -1 *raspbian*.img)

dd if=${IMGNAME} of=${MICROSDDEVICE} bs=4MB status=progress
