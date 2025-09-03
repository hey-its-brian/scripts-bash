`lsmod | grep apex`
if blank, continue:

`echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
`curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
`sudo apt-get update

`sudo apt-get install gasket-dkms libedgetpu1-std`
`sudo sh -c "echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"apex\"' >> /etc/udev/rules.d/65-apex.rules"
`sudo groupadd apex
`sudo adduser $USER apex

REBOOT
`lspci -nn | grep 089a`
you should see: 03:00.0 System peripheral: Device 1ac1:089a

`ls /dev/apex_0`
should see this:  /dev/apex_0