#!/bin/bash

# This script runs through all the commands

# Setup Network
net-setup
clear
read -p "Press enter to continue"

# Drive Setup
parted -a optimal --script /dev/nvme0n1 \
    mklabel gpt \
    mkpart primary 1MiB 257MiB \
    name 1 efi \
    set 1 esp on \
    mkpart primary 257MiB 513MiB \
    name 2 boot \
    set 2 boot on \
    mkpart primary 513MiB 100% \
    name 3 gentoo \
    set 3 lvm on
    
parted -a optimal --script /dev/nvme1n1 \
    mklabel gpt \
    mkpart primary 1MiB 100% \
    name 1 gentoo \
    set 1 lvm on
    
lsblk
read -p "Press enter to continue"

# Creating LVM

## Physical Devices
pvcreate /dev/nvme0n1p3
pvcreate /dev/nvme1n1p1
pvdisplay
read -p "Press enter to continue"

## Volume Group
vgcreate gentoo /dev/nvme0n1p3 /dev/nvme1n1p1
vgdisplay
read -p "Press enter to continue"

## Logical Volume
lvcreate -n tmp -L 5G gentoo
lvcreate -n varlog -L 5G gentoo
lvcreate -n root -l100%FREE gentoo
lvdisplay
read -p "Press enter to continue"

# Filesystem
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 -L boot /dev/nvme0n1p2

mkfs.btrfs -L root /dev/mapper/gentoo-root
mkfs.btrfs -L varlog /dev/mapper/gentoo-varlog
mkfs.btrfs -L tmp /dev/mapper/gentoo-tmp

read -p "Press enter to continue"

# Mount Filesystem
mount /dev/mapper/gentoo-root /mnt/gentoo
mkdir -p /mnt/gentoo/{tmp,var/log}
mount /dev/mapper/gentoo-tmp /mnt/gentoo/tmp
mount /dev/mapper/gentoo-varlog /mnt/gentoo/var/log
clear
lsblk

read -p "Press enter to continue"

date

read -p "Is the date correct?"

echo "Updating the time"
ntpd -q -g

echo "Changing the directory to /mnt/gentoo"
cd /mnt/gentoo
