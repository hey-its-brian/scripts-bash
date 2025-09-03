

# Add admin user
sudo useradd -m USERNAME
sudo passwd USERNAME
sudo usermod -aG sudo USERNAME


# format drive
## ext4 file system
## sdb1 partition
sudo mkfs -t ext4 /dev/sdb1


