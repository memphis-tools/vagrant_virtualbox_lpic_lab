# Linux / Infrastructure Learning Lab

made by ChatGPT https://chatgpt.com/

This document contains exercises, commands and subjects to practice using the
Vagrant infrastructure lab.

The goal is not only to know commands, but to understand how the different
Linux components interact.

> ⚠️ Exercises involving disks, LVM, LUKS, networking, firewall rules or
> deletion should only be performed on disposable lab VMs.

---

## 1. Vagrant / Lab Management

### Basic Vagrant operations

- [ ] `vagrant status`
- [ ] `vagrant up`
- [ ] `vagrant halt`
- [ ] `vagrant destroy`
- [ ] `vagrant provision`
- [ ] `vagrant ssh <host>`
- [ ] `vagrant ssh <host> -c '<command>'`
- [ ] `vagrant global-status`
- [ ] `vagrant validate`

### Clean deployment

- [ ] Destroy the complete lab
- [ ] Verify that no VM remains
- [ ] Verify that no unexpected files remain
- [ ] Recreate the complete lab
- [ ] Verify that every VM starts correctly
- [ ] Verify that every VM is correctly provisioned
- [ ] Verify that all services are functional

```bash
vagrant destroy -f
vagrant up
vagrant status
```

### Reproducibility

- [ ] Determine which configuration survives `vagrant destroy`
- [ ] Determine which configuration is generated during provisioning
- [ ] Identify files that should never be manually modified
- [ ] Identify manual steps that should become Ansible tasks
- [ ] Create an automated post-deployment test

---

# 2. Ansible

## Basics

- [ ] Understand inventory structure
- [ ] Understand groups and group variables
- [ ] Understand host variables
- [ ] Understand `become`
- [ ] Understand handlers
- [ ] Understand registered variables
- [ ] Understand `when`
- [ ] Understand loops
- [ ] Understand templates
- [ ] Understand Ansible facts
- [ ] Understand tags
- [ ] Understand idempotency

### Useful commands

```bash
ansible --version

ansible-inventory \
    -i vagrant_playbooks/inventory.ini \
    --graph

ansible-inventory \
    -i vagrant_playbooks/inventory.ini \
    --list

ansible all \
    -i vagrant_playbooks/inventory.ini \
    -m ping

ansible <host> \
    -i vagrant_playbooks/inventory.ini \
    -m setup
```

### Exercises

- [ ] Run an Ansible playbook twice and verify that the second run changes nothing
- [ ] Replace a shell command with an Ansible module
- [ ] Add a handler for a service restart
- [ ] Add a configuration template
- [ ] Add a variable instead of hard-coding a value
- [ ] Use `ansible.builtin.assert`
- [ ] Use `check_mode`
- [ ] Use `diff`
- [ ] Use tags to provision only part of a VM
- [ ] Make a playbook safe to run repeatedly
- [ ] Identify non-idempotent tasks in the project
- [ ] Improve error handling in existing playbooks
- [ ] Reduce duplication between playbooks

### Test mode

```bash
ansible-playbook \
    -i vagrant_playbooks/inventory.ini \
    playbook.yml \
    --check

ansible-playbook \
    -i vagrant_playbooks/inventory.ini \
    playbook.yml \
    --check --diff
```

---

# 3. Linux System Administration

## Files and permissions

- [ ] Practice `find`
- [ ] Practice `xargs`
- [ ] Practice `stat`
- [ ] Practice `file`
- [ ] Practice symbolic links
- [ ] Practice hard links
- [ ] Practice ACLs
- [ ] Practice extended attributes
- [ ] Understand `umask`
- [ ] Understand SUID
- [ ] Understand SGID
- [ ] Understand sticky bit

```bash
ls -lah
stat <file>
find /etc -type f
getfacl <file>
setfacl -m u:user:rwx <file>
getfattr -d <file>
```

## Processes

- [ ] `ps`
- [ ] `top`
- [ ] `htop`
- [ ] `pgrep`
- [ ] `pkill`
- [ ] `kill`
- [ ] `killall`
- [ ] `nice`
- [ ] `renice`
- [ ] Understand process states
- [ ] Understand zombie processes
- [ ] Understand parent/child processes

```bash
ps aux
ps -ef --forest
pgrep -a <process>
top
htop
```

## Performance

- [ ] `uptime`
- [ ] `free`
- [ ] `vmstat`
- [ ] `iostat`
- [ ] `sar`
- [ ] `pidstat`
- [ ] `dstat` / equivalent tools
- [ ] Understand load average
- [ ] Understand CPU wait
- [ ] Understand I/O wait
- [ ] Understand memory cache
- [ ] Identify a CPU bottleneck
- [ ] Identify an I/O bottleneck
- [ ] Identify memory pressure

```bash
uptime
free -h
vmstat 1
iostat -xz 1
sar -q
sar -r
sar -n DEV
```

---

# 4. systemd

## Services

- [ ] `systemctl start`
- [ ] `systemctl stop`
- [ ] `systemctl restart`
- [ ] `systemctl reload`
- [ ] `systemctl enable`
- [ ] `systemctl disable`
- [ ] `systemctl mask`
- [ ] `systemctl unmask`
- [ ] `systemctl status`
- [ ] `systemctl cat`
- [ ] `systemctl edit`

```bash
systemctl status <service>
systemctl cat <service>
systemctl list-units --type=service
systemctl list-unit-files
```

## Logs

- [ ] `journalctl`
- [ ] Logs for current boot
- [ ] Logs for previous boot
- [ ] Logs for a specific service
- [ ] Logs since a specific time
- [ ] Follow logs in real time

```bash
journalctl -b
journalctl -b -1
journalctl -u <service>
journalctl -u <service> -b
journalctl -f
journalctl --since "1 hour ago"
```

## Boot analysis

- [ ] `systemd-analyze`
- [ ] `systemd-analyze blame`
- [ ] `systemd-analyze critical-chain`
- [ ] Understand `After=`
- [ ] Understand `Before=`
- [ ] Understand `Requires=`
- [ ] Understand `Wants=`
- [ ] Understand `Requisite=`
- [ ] Understand `Condition=`
- [ ] Understand systemd targets
- [ ] Create a custom service
- [ ] Create a systemd timer

```bash
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
systemctl list-dependencies multi-user.target
```

### Exercise: boot dependency problem

Use the `analyzer` VM.

Investigate why:

```bash
systemctl status luks-data.service
```

can fail during boot but succeed later after:

```bash
systemctl restart luks-data.service
```

Investigate:

```bash
journalctl -b -u luks-data.service
journalctl -b -u iscsid.service
journalctl -b -u iscsi.service
journalctl -b -u multipathd.service

systemd-analyze critical-chain
systemctl list-dependencies luks-data.service
```

Goal:

- [ ] Understand the dependency chain
- [ ] Identify what device is missing at boot
- [ ] Identify which service creates that device
- [ ] Fix the dependency rather than adding an arbitrary delay
- [ ] Test after a complete VM reboot
- [ ] Test after destroying and recreating the VM

---

# 5. Storage

## Basic disk investigation

- [ ] `lsblk`
- [ ] `blkid`
- [ ] `findmnt`
- [ ] `/dev/disk/by-id`
- [ ] `/dev/disk/by-uuid`
- [ ] `fdisk`
- [ ] `parted`
- [ ] `file`
- [ ] `wipefs`

```bash
lsblk
lsblk -f
blkid
findmnt
ls -lah /dev/disk/by-id/
ls -lah /dev/disk/by-uuid/
```

## udev

- [ ] Understand udev rules
- [ ] Understand device events
- [ ] Use `udevadm info`
- [ ] Use `udevadm monitor`
- [ ] Create a simple udev rule
- [ ] Understand `/dev/disk/by-id`
- [ ] Understand WWID

```bash
udevadm info --query=all --name=/dev/sdb
udevadm monitor --kernel --udev
udevadm test /sys/class/block/sdb
```

Investigate:

```bash
ls -l /dev/disk/by-id/
```

Goal:

- [ ] Identify a disk by stable properties rather than `/dev/sdX`
- [ ] Understand why `/dev/sda`, `/dev/sdb`, etc. should not be blindly relied upon

---

# 6. LVM

- [ ] Create a physical volume
- [ ] Create a volume group
- [ ] Create a logical volume
- [ ] Extend a logical volume
- [ ] Extend a filesystem
- [ ] Reduce a logical volume in a safe lab
- [ ] Remove an LV
- [ ] Remove a VG
- [ ] Remove a PV
- [ ] Understand LVM metadata

```bash
pvs
vgs
lvs
lvdisplay
vgdisplay
pvdisplay
```

For a detailed view:

```bash
lvs -a -o +devices
```

Exercises:

- [ ] Create `vg_lab`
- [ ] Create `lv_test`
- [ ] Format it
- [ ] Mount it
- [ ] Extend it
- [ ] Extend the filesystem
- [ ] Reboot
- [ ] Verify that it is still available

---

# 7. iSCSI / SAN / Multipath

This is one of the main areas of this lab.

## iSCSI

- [ ] Understand initiator vs target
- [ ] Discover an iSCSI target
- [ ] Login to a target
- [ ] Logout from a target
- [ ] List sessions
- [ ] Inspect session details
- [ ] Understand persistent sessions

```bash
iscsiadm -m session
iscsiadm -m session -P 3
iscsiadm -m node
```

## Multipath

- [ ] Understand multiple paths to one SAN device
- [ ] Understand WWID
- [ ] Understand `/etc/multipath.conf`
- [ ] Understand `multipathd`
- [ ] Identify paths
- [ ] Identify the multipath map
- [ ] Simulate a failed path
- [ ] Restore the path

```bash
multipath -ll
multipath -t
systemctl status multipathd
journalctl -u multipathd
```

Exercises:

- [ ] Identify the WWID of the SAN device
- [ ] Document the WWID
- [ ] Configure `/etc/multipath.conf`
- [ ] Verify the resulting `/dev/mapper/...` device
- [ ] Reboot and verify persistence
- [ ] Simulate a path failure
- [ ] Verify that the multipath device remains available

---

# 8. LUKS / Encryption

- [ ] Understand LUKS
- [ ] Create a LUKS volume
- [ ] Add a LUKS key
- [ ] Remove a LUKS key
- [ ] Open a LUKS volume
- [ ] Close a LUKS volume
- [ ] Inspect LUKS metadata
- [ ] Understand `/etc/crypttab`
- [ ] Understand `systemd-cryptsetup`
- [ ] Automate unlocking during boot

```bash
cryptsetup status <name>
cryptsetup luksDump <device>
lsblk -f
```

Lab exercise:

```text
SAN
 ↓
iSCSI
 ↓
multipath
 ↓
LVM
 ↓
LUKS
 ↓
filesystem
 ↓
application
```

- [ ] Document this complete dependency chain for `analyzer`
- [ ] Determine which component creates each `/dev/mapper/...` device
- [ ] Determine which systemd unit waits for each device
- [ ] Test the chain after reboot
- [ ] Test the chain after `vagrant destroy` / `vagrant up`

---

# 9. Filesystems

- [ ] ext4
- [ ] XFS
- [ ] Mount options
- [ ] `/etc/fstab`
- [ ] UUID-based mounts
- [ ] `findmnt`
- [ ] `df`
- [ ] `du`
- [ ] inode usage
- [ ] filesystem repair
- [ ] filesystem quotas

```bash
df -h
df -i
du -xh --max-depth=1 /
findmnt
```

Exercises:

- [ ] Create a filesystem
- [ ] Mount it using UUID
- [ ] Reboot
- [ ] Verify automatic mounting
- [ ] Break the `fstab` entry in a disposable VM
- [ ] Diagnose the boot problem
- [ ] Repair it

---

# 10. Networking

## Basic networking

- [ ] `ip addr`
- [ ] `ip link`
- [ ] `ip route`
- [ ] `ip neigh`
- [ ] `ss`
- [ ] `ping`
- [ ] `tracepath`
- [ ] `arping`
- [ ] `ethtool`

```bash
ip -br addr
ip route
ip -6 route
ip neigh
ss -lntup
```

## Troubleshooting

Practice answering:

> Is the problem DNS, routing, firewall, TCP, or the application?

Useful commands:

```bash
ping <host>
getent hosts <host>
dig <host>
ss -lntup
ip route
tcpdump -ni any
```

Exercises:

- [ ] Break DNS resolution
- [ ] Diagnose it
- [ ] Break a route
- [ ] Diagnose it
- [ ] Block a port with the firewall
- [ ] Diagnose it
- [ ] Stop an application
- [ ] Determine whether the port is still listening
- [ ] Capture a TCP connection with `tcpdump`

---

# 11. IPv6

- [ ] Understand IPv6 addresses
- [ ] Understand link-local addresses
- [ ] Understand global addresses
- [ ] Understand IPv6 routing
- [ ] Understand SLAAC
- [ ] Understand IPv6 DNS records
- [ ] Configure an IPv6 address
- [ ] Test IPv6 connectivity
- [ ] Test IPv6 firewall rules

```bash
ip -6 addr
ip -6 route
ping -6 <host>
ss -6 -lntup
```

Exercises:

- [ ] Add IPv6 connectivity between two VMs
- [ ] Add AAAA records
- [ ] Test an IPv6-only service
- [ ] Compare IPv4 and IPv6 routing
- [ ] Check firewall behaviour for both protocols

---

# 12. Firewall / nftables

- [ ] Understand Netfilter
- [ ] Understand nftables
- [ ] Create a basic ruleset
- [ ] Allow SSH
- [ ] Allow HTTP/HTTPS
- [ ] Block a port
- [ ] Allow traffic from a specific network
- [ ] Understand counters
- [ ] Understand connection tracking
- [ ] Understand IPv4 vs IPv6 rules

```bash
nft list ruleset
nft list tables
nft list ruleset -a
```

Exercises:

- [ ] Create a basic firewall on a disposable VM
- [ ] Block TCP/22
- [ ] Restore SSH access
- [ ] Allow TCP/80
- [ ] Add IPv6 rules
- [ ] Add counters
- [ ] Verify rules using `tcpdump`

---

# 13. DNS

Using `dns1` and `dns2`.

## Basic DNS

- [ ] Understand authoritative DNS
- [ ] Understand recursive DNS
- [ ] Understand primary/secondary DNS
- [ ] Understand SOA
- [ ] Understand NS
- [ ] Understand A
- [ ] Understand AAAA
- [ ] Understand CNAME
- [ ] Understand MX
- [ ] Understand TXT
- [ ] Understand SRV
- [ ] Understand PTR

```bash
dig example.local
dig @dns1 example.local
dig @dns2 example.local
dig example.local SOA
dig example.local NS
dig example.local MX
dig -x <ip-address>
```

## DNS troubleshooting

- [ ] `dig`
- [ ] `host`
- [ ] `nslookup`
- [ ] `delv`
- [ ] `rndc`
- [ ] Check zone syntax
- [ ] Check SOA serial
- [ ] Check zone transfers
- [ ] Diagnose NXDOMAIN
- [ ] Diagnose SERVFAIL
- [ ] Diagnose stale secondary data

Example:

```bash
dig @dns1 <zone> SOA
dig @dns2 <zone> SOA

dig @dns1 <host> A
dig @dns2 <host> A
```

## DNSSEC

- [ ] Understand DNSSEC
- [ ] Understand DNSKEY
- [ ] Understand DS
- [ ] Understand RRSIG
- [ ] Understand NSEC/NSEC3
- [ ] Enable DNSSEC on a lab zone
- [ ] Verify signatures
- [ ] Break DNSSEC deliberately
- [ ] Diagnose validation failure

```bash
dig <zone> SOA +dnssec
dig <host> A +dnssec
dig <zone> DNSKEY +dnssec
```

---

# 14. DNS over TLS

- [ ] Understand DNS over TLS
- [ ] Understand port 853
- [ ] Understand certificate validation
- [ ] Configure a lab DoT service
- [ ] Test TLS negotiation
- [ ] Verify certificate validation
- [ ] Capture traffic and verify that DNS queries are not visible in plaintext

```bash
openssl s_client \
    -connect <dns-server>:853 \
    -servername <dns-name>
```

---

# 15. TLS / PKI / Certificates

- [ ] Create a CA
- [ ] Create a server certificate
- [ ] Create a client certificate
- [ ] Create a certificate signing request
- [ ] Verify certificate chains
- [ ] Understand SAN
- [ ] Understand certificate expiration
- [ ] Understand private-key permissions
- [ ] Install a CA certificate
- [ ] Test certificate validation

```bash
openssl x509 -in certificate.crt -text -noout
openssl verify -CAfile ca.crt certificate.crt
openssl s_client -connect <host>:443 -servername <host>
```

Exercises:

- [ ] Create certificates for `apache`
- [ ] Create certificates for `nginx`
- [ ] Create certificates for `openldap`
- [ ] Create certificates for mail services
- [ ] Add the CA to the Debian trust store
- [ ] Verify that clients trust the certificates

---

# 16. Postfix / Mail

Using the `dovecot` and other mail-related services.

## Postfix

- [ ] Understand MTA / MDA / MUA
- [ ] Understand SMTP
- [ ] Understand SMTP relay
- [ ] Understand local delivery
- [ ] Understand aliases
- [ ] Understand queues
- [ ] Understand SASL
- [ ] Understand TLS
- [ ] Understand SPF
- [ ] Understand DKIM
- [ ] Understand DMARC
- [ ] Understand DANE
- [ ] Understand open relay risks

```bash
postconf -n
postfix check
postqueue -p
postqueue -f
```

Inspect a message:

```bash
postcat -vq <queue-id>
```

Test SMTP:

```bash
openssl s_client \
    -starttls smtp \
    -connect <mail-server>:25
```

Exercises:

- [ ] Send mail from one VM to another
- [ ] Inspect the Postfix queue
- [ ] Force queue processing
- [ ] Diagnose a rejected message
- [ ] Diagnose a deferred message
- [ ] Configure SMTP TLS
- [ ] Configure SMTP AUTH
- [ ] Verify that the server is not an open relay
- [ ] Configure SPF
- [ ] Investigate DKIM
- [ ] Investigate DMARC
- [ ] Investigate DANE

---

# 17. Dovecot

- [ ] Understand IMAP
- [ ] Understand POP3
- [ ] Understand Maildir
- [ ] Understand authentication
- [ ] Understand TLS
- [ ] Understand Dovecot SASL

```bash
doveconf -n
doveconf -a
doveadm
```

Exercises:

- [ ] Create a test mailbox
- [ ] Deliver mail through Postfix
- [ ] Access the mailbox using IMAP
- [ ] Test TLS
- [ ] Test authentication
- [ ] Integrate Dovecot authentication with Postfix

---

# 18. OpenLDAP

Using `openldap`.

- [ ] Understand LDAP directory structure
- [ ] Understand DN
- [ ] Understand RDN
- [ ] Understand OU
- [ ] Understand objectClass
- [ ] Understand attributes
- [ ] Understand schemas
- [ ] Understand LDAP authentication
- [ ] Understand StartTLS
- [ ] Understand LDAPS
- [ ] Understand ACLs

```bash
ldapsearch -x \
    -H ldap://openldap \
    -b "<base-dn>"
```

```bash
ldapwhoami -x
```

Exercises:

- [ ] Create an organizational unit
- [ ] Create a user
- [ ] Create a group
- [ ] Search for users
- [ ] Modify an LDAP entry
- [ ] Delete an LDAP entry
- [ ] Configure LDAP TLS
- [ ] Test LDAP authentication
- [ ] Configure a Debian VM to use LDAP for NSS
- [ ] Configure LDAP authentication through PAM
- [ ] Investigate LDAP ACLs
- [ ] Backup the LDAP database
- [ ] Restore the LDAP database

---

# 19. Kerberos

Using `kdc`.

- [ ] Understand Kerberos realms
- [ ] Understand principals
- [ ] Understand tickets
- [ ] Understand TGT
- [ ] Understand service tickets
- [ ] Understand SPNs
- [ ] Understand keytabs
- [ ] Understand time synchronization

```bash
kinit <user>
klist
kdestroy
kvno <service>
```

Exercises:

- [ ] Create a Kerberos principal
- [ ] Authenticate using `kinit`
- [ ] Inspect the ticket cache
- [ ] Destroy tickets
- [ ] Create a service principal
- [ ] Create a keytab
- [ ] Authenticate a service using a keytab
- [ ] Break time synchronization and observe the effect
- [ ] Investigate Kerberos + LDAP integration

---

# 20. Apache / Nginx / Tomcat

## Apache

```bash
apachectl configtest
apachectl -S
systemctl status apache2
```

- [ ] Virtual hosts
- [ ] TLS
- [ ] Access logs
- [ ] Error logs
- [ ] Reverse proxy
- [ ] Authentication
- [ ] HTTP headers

## Nginx

```bash
nginx -t
nginx -T
systemctl status nginx
```

- [ ] Server blocks
- [ ] TLS
- [ ] Reverse proxy
- [ ] Load balancing
- [ ] Access logs
- [ ] Error logs

## Tomcat

- [ ] Deploy a WAR
- [ ] Configure a connector
- [ ] Configure TLS
- [ ] Put Apache in front of Tomcat
- [ ] Put Nginx in front of Tomcat
- [ ] Investigate Tomcat logs
- [ ] Understand Java heap settings

---

# 21. Maven

Using `maven`.

- [ ] Understand Maven project structure
- [ ] `pom.xml`
- [ ] Dependencies
- [ ] Repositories
- [ ] Build lifecycle
- [ ] Packaging
- [ ] WAR generation
- [ ] Deploy an application to Tomcat

```bash
mvn clean
mvn test
mvn package
```

Exercises:

- [ ] Build a simple Java application
- [ ] Build a WAR
- [ ] Deploy it to Tomcat
- [ ] Configure Maven dependencies
- [ ] Investigate a failed build
- [ ] Move application artifacts into the appropriate Vagrant template structure

---

# 22. Squid

Using `squid`.

- [ ] Understand forward proxy
- [ ] Configure allowed networks
- [ ] Configure ACLs
- [ ] Configure HTTP access
- [ ] Inspect logs
- [ ] Test a client through Squid
- [ ] Block a domain
- [ ] Allow only selected destinations

```bash
squid -k parse
systemctl status squid
tail -f /var/log/squid/access.log
```

Test:

```bash
curl -x http://squid:3128 http://example.com/
```

---

# 23. OpenVPN

Using `openvpn`.

- [ ] Understand TUN/TAP
- [ ] Understand client/server architecture
- [ ] Understand certificates
- [ ] Understand PKI
- [ ] Understand routing through VPN
- [ ] Understand pushed routes
- [ ] Understand DNS through VPN
- [ ] Configure a client
- [ ] Configure a server
- [ ] Troubleshoot a failed tunnel

```bash
ip addr
ip route
systemctl status openvpn*
journalctl -u 'openvpn*'
```

Exercises:

- [ ] Connect a client to the VPN
- [ ] Verify the tunnel interface
- [ ] Verify routes
- [ ] Access an internal service through the VPN
- [ ] Break a certificate and diagnose the failure
- [ ] Break a route and diagnose the failure
- [ ] Test VPN + DNS
- [ ] Test VPN + firewall

---

# 24. Backup / Bacula

Using `bacula`.

- [ ] Understand Director
- [ ] Understand File Daemon
- [ ] Understand Storage Daemon
- [ ] Understand jobs
- [ ] Understand schedules
- [ ] Understand pools
- [ ] Understand volumes
- [ ] Understand retention
- [ ] Understand restore jobs

Exercises:

- [ ] Create a backup job
- [ ] Run a backup
- [ ] Inspect the job
- [ ] Verify the backup
- [ ] Delete a test file
- [ ] Restore the file
- [ ] Perform a complete test restore
- [ ] Test backup after destroying/recreating a client VM
- [ ] Review Bacula credentials/tokens
- [ ] Ensure credentials are not unnecessarily reused

---

# 25. Logging / Logrotate

- [ ] Understand `/var/log`
- [ ] Understand journald
- [ ] Understand logrotate
- [ ] Create a logrotate configuration
- [ ] Rotate logs manually
- [ ] Understand compression
- [ ] Understand retention
- [ ] Understand application logs

```bash
logrotate -d /etc/logrotate.conf
logrotate -f /etc/logrotate.conf
journalctl --disk-usage
```

Exercises:

- [ ] Configure rotation for a custom application
- [ ] Verify permissions after rotation
- [ ] Verify that the application continues logging
- [ ] Configure retention
- [ ] Investigate a service with excessive logging

---

# 26. Kernel / Modules

- [ ] Understand kernel version
- [ ] Understand kernel modules
- [ ] `lsmod`
- [ ] `modprobe`
- [ ] `modinfo`
- [ ] `depmod`
- [ ] `/etc/modprobe.d/`
- [ ] Blacklist a module
- [ ] Load a module automatically

```bash
uname -a
lsmod
modinfo <module>
modprobe <module>
depmod -a
```

### Kernel compilation

- [ ] Obtain Linux kernel source
- [ ] Configure a kernel
- [ ] Compile a kernel
- [ ] Install a kernel
- [ ] Boot the new kernel
- [ ] Compare configurations
- [ ] Return to the previous kernel

### Kernel patching

- [ ] Apply a small kernel patch
- [ ] Build the patched kernel
- [ ] Boot it
- [ ] Verify the change
- [ ] Document the patch

> Prefer a disposable VM for kernel experiments.

---

# 27. Package Management / Patching

## Debian

- [ ] `apt update`
- [ ] `apt upgrade`
- [ ] `apt full-upgrade`
- [ ] `apt install`
- [ ] `apt remove`
- [ ] `apt purge`
- [ ] `apt autoremove`
- [ ] `apt-cache`
- [ ] `dpkg`

```bash
apt update
apt list --upgradable
apt policy <package>
dpkg -l
dpkg -S /path/to/file
```

Exercises:

- [ ] Find which package owns a file
- [ ] Find package versions
- [ ] Install an older version
- [ ] Hold a package
- [ ] Remove and reinstall a package
- [ ] Investigate a broken package installation

## Patch management

- [ ] Determine which VMs need updates
- [ ] Patch one VM
- [ ] Reboot when required
- [ ] Verify services
- [ ] Patch all VMs using Ansible
- [ ] Make the patching process repeatable

---

# 28. Security / Hardening

- [ ] SSH hardening
- [ ] Disable unnecessary services
- [ ] Review listening ports
- [ ] Review users
- [ ] Review sudo permissions
- [ ] Review file permissions
- [ ] Review SUID/SGID files
- [ ] Review firewall rules
- [ ] Review TLS certificates
- [ ] Review expired certificates
- [ ] Review secrets in Ansible
- [ ] Review credentials in Vagrant files
- [ ] Review Bacula credentials
- [ ] Investigate Ansible Vault
- [ ] Investigate secret management

Useful commands:

```bash
ss -lntup
systemctl --type=service --state=running
getent passwd
getent group
sudo -l
find / -perm /6000 -type f 2>/dev/null
```

---

# 29. Filesystem Quotas

- [ ] Understand user quotas
- [ ] Understand group quotas
- [ ] Enable quotas
- [ ] Set a quota
- [ ] Test quota enforcement
- [ ] Monitor quota usage

```bash
df -h
df -i
quota
repquota
```

---

# 30. System Limits

- [ ] Understand `ulimit`
- [ ] Understand soft limits
- [ ] Understand hard limits
- [ ] Understand `/etc/security/limits.conf`
- [ ] Understand systemd resource limits
- [ ] Test open-file limits

```bash
ulimit -a
ulimit -n
cat /proc/<pid>/limits
```

Exercises:

- [ ] Change the maximum number of open files
- [ ] Verify the new limit
- [ ] Configure a systemd service with a custom limit
- [ ] Generate enough files/connections to hit the limit

---

# 31. Archives / Compression

- [ ] `tar`
- [ ] `gzip`
- [ ] `bzip2`
- [ ] `xz`
- [ ] `cpio`
- [ ] Understand archive vs compression

```bash
tar -cvf archive.tar directory/
tar -xvf archive.tar

tar -czvf archive.tar.gz directory/
tar -xzvf archive.tar.gz

find . -type f -print | cpio -ov > archive.cpio
```

Exercises:

- [ ] Create an archive
- [ ] Extract only one file
- [ ] Compare tar.gz and tar.xz
- [ ] Create a cpio archive
- [ ] Restore files with correct permissions

---

# 32. Troubleshooting Exercises

Practice diagnosing problems without immediately looking at the configuration.

## Service failure

- [ ] Stop a service
- [ ] Diagnose why it stopped
- [ ] Find the relevant log
- [ ] Identify the configuration error
- [ ] Fix it
- [ ] Verify recovery

## Network failure

- [ ] Stop a service listening on a port
- [ ] Diagnose with `ss`
- [ ] Test with `nc` / `curl`
- [ ] Capture traffic with `tcpdump`

## DNS failure

- [ ] Break a DNS record
- [ ] Diagnose with `dig`
- [ ] Compare primary and secondary
- [ ] Inspect SOA serial
- [ ] Restore service

## Storage failure

- [ ] Make a filesystem unavailable in a disposable VM
- [ ] Diagnose with `lsblk`
- [ ] Diagnose with `findmnt`
- [ ] Diagnose with `journalctl`
- [ ] Restore the filesystem

## Boot failure

- [ ] Introduce a bad systemd dependency
- [ ] Reboot
- [ ] Use rescue/emergency mode
- [ ] Read the journal
- [ ] Repair the configuration

---

# 33. Automation Exercises

- [ ] Replace manual commands with Ansible
- [ ] Replace duplicated Vagrant configuration
- [ ] Create reusable Ansible roles
- [ ] Create defaults
- [ ] Create handlers
- [ ] Create templates
- [ ] Use variables instead of hard-coded values
- [ ] Use Ansible Vault for secrets
- [ ] Add validation tasks
- [ ] Add assertions
- [ ] Add post-deployment tests
- [ ] Make deployment idempotent
- [ ] Make destruction/recreation reproducible

---

# 34. Project Refactoring

- [ ] Refactor the large `Vagrantfile`
- [ ] Reduce duplicated VM definitions
- [ ] Move common configuration into reusable functions
- [ ] Review naming conventions
- [ ] Rename `nas` to `nas-san` / `nas_san` if appropriate
- [ ] Review certificates after hostname changes
- [ ] Move Maven application files into the appropriate template directory
- [ ] Remove obsolete scripts
- [ ] Remove obsolete playbooks
- [ ] Review unused variables
- [ ] Review duplicated passwords/tokens
- [ ] Separate secrets from configuration
- [ ] Document important dependencies

---

# 35. Documentation Exercises

- [ ] Document the network topology
- [ ] Document IP addresses
- [ ] Document DNS zones
- [ ] Document VM dependencies
- [ ] Document service dependencies
- [ ] Document the SAN/storage chain
- [ ] Document certificate authorities
- [ ] Document authentication architecture
- [ ] Document mail flow
- [ ] Document backup flow
- [ ] Document deployment
- [ ] Document destruction
- [ ] Document recovery procedures
- [ ] Document known problems
- [ ] Generate useful documentation automatically where possible

---

# 36. Future Services / Experiments

- [ ] Gitea
- [ ] DNSSEC
- [ ] DNS over TLS
- [ ] DANE
- [ ] More application-to-admin email notifications
- [ ] Centralized logging
- [ ] Monitoring
- [ ] Metrics
- [ ] Alerting
- [ ] Configuration backup
- [ ] Automated disaster recovery test
- [ ] Automated infrastructure tests

---

# 37. Final Challenge: Rebuild the Lab

The ultimate exercise is to prove that the project is reproducible.

```bash
vagrant destroy -f
vagrant up
```

Then verify:

- [ ] All VMs are running
- [ ] All VMs have the expected hostnames
- [ ] DNS works
- [ ] SSH works
- [ ] Ansible works
- [ ] LDAP works
- [ ] Kerberos works
- [ ] SAN/iSCSI works
- [ ] Multipath works
- [ ] LVM works
- [ ] LUKS works
- [ ] Filesystems mount
- [ ] Apache works
- [ ] Nginx works
- [ ] Tomcat works
- [ ] Mail works
- [ ] Squid works
- [ ] OpenVPN works
- [ ] Bacula works
- [ ] Certificates are valid
- [ ] No manual intervention was required

The final goal is:

> **Destroy everything, recreate everything, and obtain the same working infrastructure automatically.**
