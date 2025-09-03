

# Install PiHole on existing linux install
curl -sSL https://install.pi-hole.net | bash


# Mount share drive
sudo mount /dev/sdb2 /media/drives/drive1
sudo mount /dev/sdc1 /media/drives/drive2

# Use scp
scp username@server:/home/username/file_name /home/local-username/file-name