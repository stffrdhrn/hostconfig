# Setup notes for openWRT

My router is installed with OpenWRT, basic setup notes.

## Basic Setup

 - DHCP Network/GW 192.168.1.1
 - Static Routes

```
10.9.0.0 192.168.1.31 - for QEMU
10.0.0.0 192.168.1.31 - for 10.x subnet
```

 - DNS disable local resolution only

### DNS

By default DNS relocation is only allowed for requests coming from
DHCP hosts.  That means our 10.x subnets cannot access the DNS.

We disable the limitation and ensure DNS server only binds to `br-lan`
do make sure external parties can't access DNS.
