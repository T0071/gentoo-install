#!/bin/bash

# This script wipes the drives clean of any data

nvme list

read -p "Press enter to continue"

nvme format -s1 /dev/nvme0n1
nvme format -s1 /dev/nvme1n1

read -p "Press enter to continue"

reboot
