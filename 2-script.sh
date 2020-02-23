#!/bin/bash

# This script runs through all the commands

# Bold and Normal
bold=$(tput bold)
normal=$(tput sgr0)

# Drive Setup
echo "${bold}Setting up first drive"
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
lsblk
read -p "Check if first drive is correct?"
clear

echo "${bold}Setting up second drive"
parted -a optimal --script /dev/nvme1n1 \
    mklabel gpt \
    mkpart primary 1MiB 100% \
    name 1 gentoo \
    set 1 lvm on
    
lsblk
read -p "Check if second drive is correct?"
clear

# Creating LVM

## Physical Devices
echo "${bold}Setting up Physical Devices for LVM..."
pvcreate /dev/nvme0n1p3
pvcreate /dev/nvme1n1p1
pvdisplay
read -p "Check Physical Devices?"

## Volume Group
echo "${bold}Setting up Volume Group for LVM..."
vgcreate gentoo /dev/nvme0n1p3 /dev/nvme1n1p1
vgdisplay
read -p "Check Volume Group?"

## Logical Volume
echo "${bold}Setting up Logical Volumes for LVM..."
lvcreate -n tmp -L 5G gentoo
lvcreate -n varlog -L 5G gentoo
lvcreate -n root -l100%FREE gentoo
lvdisplay
read -p "Check Logical Volume?"
clear

# Filesystem
echo "${bold}Setting Filesystem fat for boot partition"
mkfs.fat -F 32 /dev/nvme0n1p1
echo "${bold}Setting Filesystem ext4 for efi partition"
mkfs.ext4 -L boot /dev/nvme0n1p2
clear
read -p "Press enter to continue"

echo "${bold}Setting Filesystem btrfs for root"
mkfs.btrfs -L root /dev/mapper/gentoo-root
echo "${bold}Setting Filesystem btrfs for varlog"
mkfs.btrfs -L varlog /dev/mapper/gentoo-varlog
echo "${bold}Setting Filesystem btrfs for tmp"
mkfs.btrfs -L tmp /dev/mapper/gentoo-tmp

read -p "Press enter to continue"
clear

# Mount Filesystem
echo "${bold}Mounting gentoo-root to /mnt/gentoo"
mount /dev/mapper/gentoo-root /mnt/gentoo
echo "${bold}Creating Directories for mount"
mkdir -p /mnt/gentoo/{tmp,var/log}
echo "${bold}Mounting gentoo-tmp to /mnt/gentoo/tmp"
mount /dev/mapper/gentoo-tmp /mnt/gentoo/tmp
echo "${bold}Mounting gentoo-varlog to /mnt/gentoo/var/log"
mount /dev/mapper/gentoo-varlog /mnt/gentoo/var/log

lsblk

read -p "Check mount?"
clear

echo "${bold}Current Date:"
date
read -p "Is the date correct?"

echo "${bold}Updating the time"
ntpd -q -g
