# Setup notes for raspberry pi

## Basic Setup

All basic setup like initial IP address, enable ssh and swtich to headless
is in the basic config system.

```
 raspi-config
```

## Static IP

I want to setup static IPs so I know where my hosts are.

*Note* wired ip, i.e. eth0, won't show up until actually plugged in.

Edit file:

```
  /etc/dhcpcd.conf
```

Example:
```
# After top part ...

interface eth0
static ip_address=10.0.0.31/8

interface wlan0
static ip_address=192.168.1.31/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
static domain_search=shorne-pla.net
```

When done we do `systemctl restart dhcpcd.service` to restart networks and apply
settings.  We may lose connectivity after this.

## User
Create a user, reset the default `pi` password

As pi, create new user

```
 useradd shorne
 usermod -G sudo shorne
```

As new user, disable pi

```
 passwd -l pi
```

## Update & Install Packages

Update apt packages

```
 apt-get update
 apt-get upgrade
```

Install packages

```
 apt-get install -y dnsutils vim autofs lsof rsnapshot iptables-persistent
```

If we want a webserver, usually not, install more

```
 apt-get install -y apache2
```

## Firewall

Setup firewall to stop intruders trying to brute force password.  This is
from https://lwn.net/Articles/704292/.

```
 iptables -A INPUT -p tcp -m state --state NEW --dport 22 -m recent \
  --name sshrate --set

 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent \
  --name sshrate --rcheck --seconds 60 --hitcount 4 -j LOG \
  --log-prefix "SSH REJECT: "

 iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent \
  --name sshrate --rcheck --seconds 60 --hitcount 4 -j REJECT \
  --reject-with tcp-reset
```

If you get an IP that you want to stop permanently.  i.e. you see lots of
failures in `dmesg` you can permanently disable with:

```
 iptables -I INPUT 1 -s 65.55.44.100 -j DROP
```

### Routing

If you are using your pi as a router you will need to setup masquerading.  In my
can I have a configuration like this:

```

                SUBNET 1                     SUBNET 2
             192.168.1.0/24                10.0.0.0/24

  [ Wifi Router ]-<)      (>--[(wlan0) pi (eth0)]--[switch]--{subnet}

```

Here, the pi acts as the router for hosts in subnet 2 to access the internet.
My wifi router is connected to the internet.  The pi spans two subnets with
`wlan0` on the `192.168.1.0/24` and `eth0` on the `10.0.0.0/24` subnet.

To enable masquewrading (rewriting) of traffic outgoing from the `wlan0`
interface we do the following:

```
 sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
```


### Saving Changes

Changes to firewalls are automatically saved to the following files by the `iptables-persistent`
packages we installed earlier:

```
/etc/iptables/rules.v4
/etc/iptables/rules.v6
```

## Noip

We install noip so we can get to hosts even if their public IP changes.

```
 wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
 make
 make install
```

Used systemd startup for noip

 https://gist.github.com/NathanGiesbrecht/da6560f21e55178bcea7fdd9ca2e39b5

## NFS enable

For moutning hosts under `/net`

```
 systemctl enable nfs-common
 systemctl start nfs-common
```

## LVM Volumes

### Setup LVM volumes

Use `fdisk` to create a `Linux LVM` partition, then

```
 pvcreate /dev/sda1
 vgcreate data /dev/sda1
 lvcreate --name backup --size 250G data
 mkfs.ext4 /dev/mapper/data-backup
```

### Enable LVM

This doesnt work, I need to run `vgchange -ay` after reboot

```
 # Doesnt do was is expected
 systemctl enable lvm2.service

 # Perhaps this will do?
 systemctl enable lvm2-activation.service
```

### When migrating lvm volumes

http://tldp.org/HOWTO/LVM-HOWTO/recipemovevgtonewsys.html

```
 # Unmount the partition
 unmount /misc/backup

 vgchange -an data
 vgexport data
```

Unplug and physically move the drive, then on new host

```
 pvscan
 vgimport data
 vgchange -ay data
```

mount as needed, usually just via automount as below

## automounter

We use automounter to allow mounting on demand.

 - edit /etc/auto.master, enable net, enable misc
 - edit /etc/auto.misc  , enable backup to /dev/sda1

Restart will create /net and /misc directories

```
 systemctl restart autofs.service
```

## SSH Keys

On pi generate keys, if needed only.  Or from your remote host if you want
to have password less login to the pi.

```
 ssh-keygen -t rsa -b 4096 -C "shorne@$(hostname)"
``` 

Then copy your key to the destination host.

```
 cat ~/.ssh/id_rsa.pub | ssh shorne@${remotehost} \
   "cat >> ~/.ssh/authorized_keys"
```

## Hosts

Add our general hosts config.

```
 cat etc/hosts >> /etc/hosts
```

Also, its a good idea to add the new host to `etc/hosts` in this project.
Then edit `/etc/hosts` to remove this host so you don't have a duplicate
with `127.0.0.1`.

## VPN

In case your PI will be installed in a location where its not accessible via a
public IP it is possible to access it by setting up a VPN.

### Server

At least one system needs to have a public VPN running in order for this to
work.  I used [pivpn](http://www.pivpn.io/) which is based on OpenVPN.  The
setup is easy if you follow the docs on the web page.  So nothing to mention
here.

### Client

Clients will connect to the server and then be available to other nodes in the
server.  To setup the client.

```
# On the server generate a new certificate configuration
pivpn add nopass
# follow prompts

# On the client

# Install openvpn client
sudo apt-get install openvpn

# Copy the openvpn conf
scp shorne@{remote_host}:/home/shorne/mypi.conf /etc/openvpn
# Lock down the file (as it contains sensitive keys)
sudo chown root.root /etc/openvpn/mypi.conf
sudo chmod 600 /etc/openvpn/mypi.conf

# Enable openvpn client
systemctl enable openvpn@mypi.service 

```

## Configure backups

For backups currently we use `rsnapshot` which provides a simple solution.

Follow as per:

 - https://wiki.centos.org/HowTos/RsnapshotBackups

The rsnapshot setup is easy just read `/etc/rsnapshot.conf` and then add it
into your crontab as needed. 

Configuring ssh keys for root is a bit tricky if you dont have a root
password.  I do:

```
 sudo -s
 if [ ! -f ~/.ssh/id_rsa.pub ] ; then
   ssh-keygen -t rsa -b 4096 -C "root@$(hostname)"
 fi
 
 remote_host=myhost
 scp ~/.ssh/id_rsa.pub shorne@${remote_host}:pi.id_rsa.pub
 ssh shorne@${remote_host}
   cat pi.id_rsa.pub | sudo sh -c "cat >> ~/.ssh/authorized_keys"
   rm pi.id_rsa.pub
   exit
```

These should now work with no pw asked

```
 ssh ${remote_host} chmod 700 .ssh
 ssh ${remote_host} chmod 400 .ssh/authorized_keys
```

### Rsnapshot offsite mirror

In order to get an offsite rsnapshot mirror in use mirror the latest
rsnapshot mirror offsite with rsnapshot.

i.e. on a mirror site

```
 backup root@pi:/var/cache/rsnapshot/hourly.0/ mirror/
```

The offsite mirror should run rsnapshot `daily`, `hourly` etc to create
snapshots and history as needed.

