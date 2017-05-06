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

# automounter
edit /etc/auto.master, enable net, enable misc
edit /etc/auto.misc  , enable backup to /dev/sda1

## restart will create /net and /misc directories
systemctl restart autofs.service

# SSH 
scp .ssh/id_rsa.pub shorne@pi:mac.id_rsa.pub

ssh-keygen -t rsa -b 4096 -C "shorne@$(hostname)"

# Hosts
/etc/hosts copy from other hosts in network

# Configure backups
apt-get install rsnapshot
