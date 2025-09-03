
# all items below are for the Mac unless otherwise noted

# hard-wipe a card in the internal Mac card reader
diskutil list                               # note the disk id, e.g. /dev/disk6
diskutil unmountDisk force /dev/disk6
sudo dd if=/dev/zero of=/dev/rdisk6 bs=1m count=10   # zero first 10 MB (kills GPT/MBR)
diskutil eraseDisk FAT32 IPOD MBRFormat /dev/disk6   # single full-size FAT32, MBR

#######################
# Combining 2 drives into 1 in Linux
#
# Logical Volume Manager
sudo apt install lvm2  # Debian/Ubuntu
sudo yum install lvm2  # CentOS/RHEL

## Create physical volumes
sudo pvcreate /dev/sdX /dev/sdY

## Create volume group
sudo vgcreate my_vg /dev/sdX /dev/sdY

## Create logical volume
sudo lvcreate -n my_lv -l 100%FREE my_vg

## Format & Mount
sudo mkfs.ext4 /dev/my_vg/my_lv
sudo mount /dev/my_vg/my_lv /mnt/my_combined_drive

###########################################

