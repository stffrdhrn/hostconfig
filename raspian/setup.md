## Setup notes for raspberry pi

# Basic setup in
raspi-config

# Ip address
# Note wired ip wont shot up until plugged in
/etc/dhcpcd.conf

# User
useradd shorne
usermod -G sudo shorne

# Update 
apt-get update
apt-get upgrade

# Packages
apt-get install -y dnsutils vim autofs  iptables-persistent
apt-get install -y apache2

# Firewall

 iptables -A INPUT -p tcp -m state --state NEW --dport 22 -m recent \
  --name sshrate --set
 
 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent \
  --name sshrate --rcheck --seconds 60 --hitcount 4 -j LOG \
  --log-prefix "SSH REJECT: "
 
 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent \
  --name sshrate --rcheck --seconds 60 --hitcount 4 -j REJECT \
  --reject-with tcp-reset

# Noip
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz

make
make install
# Used systemd startup for noip
https://gist.github.com/NathanGiesbrecht/da6560f21e55178bcea7fdd9ca2e39b5

# nfs enable
systemctl enable nfs-common
systemctl start nfs-common

# LVM Volumes

## Setup LVM volumes
Use `fdisk` to create a LVM partition, then

pvcreate /dev/sda1
vgcreate data /dev/sda1
lvcreate --name backup --size 250G data
mkfs.ext4 /dev/mapper/data-backup

## When migrating lvm volumes
http://tldp.org/HOWTO/LVM-HOWTO/recipemovevgtonewsys.html

unmount /misc/backup

 vgchange -an data
 vgexport data

Unplug/move

 pvscan
 vgimport data
 vgchange -ay data

mount

# automounter
edit /etc/auto.master, enable net, enable misc
edit /etc/auto.misc  , enable backup to /dev/sda1

## restart will create /net and /misc directories
systemctl restart autofs.service

# SSH 

# On pi generate keys, if needed only
 ssh-keygen -t rsa -b 4096 -C "shorne@$(hostname)"
 
# To login from current host to remote
 cat ~/.ssh/id_rsa.pub | ssh shorne@${remotehost} \
   "cat >> ~/.ssh/authorized_keys"

# Hosts
cat etc/hosts >> /etc/hosts
## Then edit to remove this host

# Configure backups
apt-get install rsnapshot

https://wiki.centos.org/HowTos/RsnapshotBackups


 sudo -s
 if [ ! -f ~/.ssh/id_rsa.pub ] ; then
   ssh-keygen -t rsa -b 4096 -C "root@$(hostname)"
 fi
 
 remote_host=lianli
 scp ~/.ssh/id_rsa.pub shorne@${remote_host}:pi.id_rsa.pub
 ssh shorne@${remote_host}
   cat pi.id_rsa.pub | sudo sh -c "cat >> ~/.ssh/authorized_keys"
   rm pi.id_rsa.pub
   exit

# These should now work with no pw asked
 ssh ${remote_host} chmod 700 .ssh
 ssh ${remote_host} chmod 400 .ssh/authorized_keys


## REMOTE REPLICA
This to be setup to run after rsnapshot

https://www.cyberciti.biz/faq/linux-unix-apple-osx-bsd-rsync-copy-hard-links/

 rsync -az -H --delete --numeric-ids /misc/backup/cache \
  /misc/backup2

