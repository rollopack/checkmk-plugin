# CheckMK Plugins

Collection of CheckMK monitoring plugins for Linux servers. Tested only on Debian.

## Plugins

| Plugin | Type | Description |
|---|---|---|
| `fail2ban.sh` | local check | Monitor fail2ban — CRITICAL if stopped, reports total banned IPs and per-jail list |
| `imap.sh` | local check | Check IMAP service availability via telnet |
| `debian.sh` | local check | Check Debian version age and last dist-upgrade date |
| `samba.sh` | local check | Count connected Samba clients and open files |
| `backup.sh` | local check | Check backup freshness via logrotate status files on NAS |
| `qemu.sh` | local check | Monitor QEMU/KVM virtual machines (state, memory, CPU) |
| `virsh-backup.sh` | local check | Check VM backup status and list backup data files |
| `nut.sh` | agent plugin | Dump UPS status via NUT (section `<<<nut>>>`) |
| `mk_mysql` | agent plugin | MySQL/MariaDB monitoring — ping, global status/variables (sections `<<<mysql_ping>>>`, `<<<mysql>>>`). Based on original Checkmk plugin with capacity and replica sections removed |

## Installation

### Local checks

```bash
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/fail2ban.sh -O /usr/lib/check_mk_agent/local/fail2ban.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/fail2ban.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/imap.sh -O /usr/lib/check_mk_agent/local/imap.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/imap.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/debian.sh -O /usr/lib/check_mk_agent/local/debian.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/debian.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/samba.sh -O /usr/lib/check_mk_agent/local/samba.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/samba.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/backup.sh -O /usr/lib/check_mk_agent/local/backup.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/backup.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/qemu.sh -O /usr/lib/check_mk_agent/local/qemu.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/qemu.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/virsh-backup.sh -O /usr/lib/check_mk_agent/local/virsh-backup.sh && sudo chmod 755 /usr/lib/check_mk_agent/local/virsh-backup.sh
```

### Agent plugins

```bash
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/nut.sh -O /usr/lib/check_mk_agent/plugins/nut.sh && sudo chmod 755 /usr/lib/check_mk_agent/plugins/nut.sh
sudo wget https://raw.githubusercontent.com/rollopack/checkmk-plugin/main/mk_mysql -O /usr/lib/check_mk_agent/plugins/mk_mysql && sudo chmod 755 /usr/lib/check_mk_agent/plugins/mk_mysql
```

## Additional setup

### fail2ban — sudoers

The `fail2ban.sh` check requires passwordless sudo for the `checkmk` user. Create `/etc/sudoers.d/checkmk` with:

```
checkmk ALL=(root) NOPASSWD: /usr/bin/fail2ban-client
```

### Service discovery

After installing the plugins, run service discovery on the CheckMK server:

```bash
cmk -I --all
cmk -R
```
