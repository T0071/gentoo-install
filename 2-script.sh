#!/bin/bash

# This script runs through all the commands

# Bold and Normal
bold=$(tput bold)
normal=$(tput sgr0)

clear
echo "${bold}Listing nvme drives${normal}"
nvme list

read -p "Continue?"

echo "${bold}Formatting /dev/nvme0n1${normal}"
nvme format -s1 /dev/nvme0n1
echo "${bold}Formatting /dev/nvme1n1${normal}"
nvme format -s1 /dev/nvme1n1

read -p "Press enter to continue"

# Drive Setup
echo "${bold}Setting up /dev/nvme0n1${normal}"
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
read -p "Check if /dev/nvme0n1 is correct?"

echo "${bold}Setting up /dev/nvme1n1${normal}"
parted -a optimal --script /dev/nvme1n1 \
    mklabel gpt \
    mkpart primary 1MiB 100% \
    name 1 gentoo \
    set 1 lvm on
lsblk
read -p "Check if /dev/nvme1n1 is correct?"
clear

# Creating LVM

## Physical Devices
echo "${bold}Setting up Physical Devices for LVM...${normal}"
pvcreate /dev/nvme0n1p3
pvcreate /dev/nvme1n1p1
pvdisplay
read -p "Check Physical Devices?"
clear

## Volume Group
echo "${bold}Setting up Volume Group for LVM...${normal}"
vgcreate gentoo /dev/nvme0n1p3 /dev/nvme1n1p1
vgdisplay
read -p "Check Volume Group?"
clear

## Logical Volume
echo "${bold}Setting up Logical Volumes for LVM...${normal}"
lvcreate -n tmp -L 5G gentoo
lvcreate -n varlog -L 5G gentoo
lvcreate -n root -l100%FREE gentoo
lvdisplay
read -p "Check Logical Volume?"
clear

# Filesystem
echo "${bold}Setting Filesystem fat for boot partition${normal}"
mkfs.fat -F 32 /dev/nvme0n1p1
echo "${bold}Setting Filesystem ext4 for efi partition${normal}"
mkfs.ext4 -L boot /dev/nvme0n1p2
read -p "Press enter to continue"
clear

echo "${bold}Setting Filesystem btrfs for root${normal}"
mkfs.btrfs -L root /dev/mapper/gentoo-root
echo "${bold}Setting Filesystem btrfs for varlog${normal}"
mkfs.btrfs -L varlog /dev/mapper/gentoo-varlog
echo "${bold}Setting Filesystem btrfs for tmp${normal}"
mkfs.btrfs -L tmp /dev/mapper/gentoo-tmp
read -p "Press enter to continue"
clear

# Mount Filesystem
echo "${bold}Mounting gentoo-root to /mnt/gentoo${normal}"
mount /dev/mapper/gentoo-root /mnt/gentoo
echo "${bold}Creating Directories for mount${normal}"
mkdir -p /mnt/gentoo/{tmp,var/log}
echo "${bold}Mounting gentoo-tmp to /mnt/gentoo/tmp${normal}"
mount /dev/mapper/gentoo-tmp /mnt/gentoo/tmp
echo "${bold}Mounting gentoo-varlog to /mnt/gentoo/var/log${normal}"
mount /dev/mapper/gentoo-varlog /mnt/gentoo/var/log

lsblk
read -p "Check mount?"
clear

echo "${bold}Current Date:${normal}"
date
read -p "Is the date correct?"

echo "${bold}Updating the time"
ntpd -q -g
read -p "Continue?"

echo "${bold}Installing Stage 3"
