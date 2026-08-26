# 🏡 Home Server Repository

![Debian](https://img.shields.io/badge/OS-Debian-A81D33?style=flat&logo=debian&logoColor=white)
![Android](https://img.shields.io/badge/Mobile-Android-34A853?style=flat&logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Kernel-Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Tailscale](https://img.shields.io/badge/Mesh-Tailscale-242424?style=flat&logo=tailscale&logoColor=white)
![Portainer](https://img.shields.io/badge/Manage-Portainer-13BEF9?style=flat&logo=portainer&logoColor=white)
![Beszel](https://img.shields.io/badge/Stats-Beszel-10B981?style=flat&logo=beszel&logoColor=white)
![Nextcloud](https://img.shields.io/badge/Cloud-Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)


Welcome to my home server repository! This repo documents my homelab setup, network architecture, and self-hosted services running on Debian Linux — hardware, storage, encryption, networking, Docker services, backup strategy, security hardening, and a complete rebuild procedure.

> **Security + simplicity + reliability, with minimal ongoing maintenance.**

The server intentionally avoids RAID, LVM, ZFS, or storage pooling. Each SSD is encrypted and mounted independently so drives can be replaced, disconnected, or upgraded without rebuilding the entire storage system.

---

## 📋 Table of Contents

- [Hardware Specs](#-hardware-specs)
- [Operating System](#-operating-system)
- [Storage Architecture](#-storage-architecture)
- [Disk Layout](#-disk-layout)
- [Encryption](#-encryption)
- [LUKS Recovery](#-luks-recovery)
- [Filesystem & Mount Points](#-filesystem--mount-points)
- [Networking](#-networking)
- [Tailscale](#-tailscale)
- [Docker](#-docker)
- [Docker Directory Structure](#-docker-directory-structure)
- [Currently Running Services](#-currently-running-services)
- [Planned Services](#-planned-services)
- [Automated Encrypted Backups](#-automated-encrypted-backups)
- [Security & Optimization Setup](#-security--optimization-setup)
- [Power Management](#-power-management)
- [Rebuild Procedure](#-rebuild-procedure)
- [Adding More Storage Later](#-adding-more-storage-later)
- [Recovery Procedure](#-recovery-procedure)
- [Troubleshooting](#-troubleshooting)
- [Useful Commands](#-useful-commands)
- [Secrets Policy](#-secrets-policy)
- [Installation History](#-installation-history)
- [License](#-license)

---

## 💻 Hardware Specs

| Component | Specification |
| :--- | :--- |
| **Device** | Dell Precision M4800 |
| **OS** | Debian Linux 13 (Trixie) |
| **CPU** | Intel(R) Core(TM) i7-4810MQ (8) @ 3.80 GHz |
| **RAM** | 16 GB |
| **Primary OS Drive** | Lexar SSD NS100 512 GB (SATA) |
| **Internal Additional Storage** | Samsung SSD 860 EVO mSATA 250 GB |
| **External Storage** | OCZ Vertex 450 256 GB (USB) |
| **External Backup Drive** | Samsung PM871a 256 GB (USB) |
| **Primary Interface** | Ethernet (`eno1`) |

---

## 🐧 Operating System

- **Distribution:** Debian GNU/Linux 13 (Trixie)
- **Architecture:** x86_64
- **Boot Mode:** UEFI
- **Filesystem:** ext4
- **Encryption:** LUKS / dm-crypt

The primary system SSD is fully encrypted using LUKS. The EFI and `/boot` partitions remain unencrypted so the system can boot and then prompt for the LUKS passphrase.

---

## 💾 Storage Architecture

The server uses four SSDs, kept **independent** on purpose:

- No RAID
- No LVM
- No ZFS
- No mergerfs
- No Btrfs storage pool
- No combined filesystem spanning multiple SSDs

Each additional SSD can be encrypted, mounted, disconnected, replaced, and restored independently — avoiding dependencies between physical drives.

---

## 🗄️ Disk Layout

### 1. Lexar 512 GB — Main System Drive

- **Model:** `Lexar SSD NS100 512GB`
- **Serial:** `NM7373R0047070S304`
- **Device:** `/dev/sda`

```text
/dev/sda
├── /dev/sda1       953 MB   EFI System Partition
├── /dev/sda2       977 MB   /boot
└── /dev/sda3       475.1 GB LUKS
    └── sda3_crypt  475 GB   ext4 /
```

Contains: Debian, Docker + Docker volumes/config, Nextcloud, system files, applications.

### 2. Samsung 860 EVO mSATA 250 GB

- **Model:** `Samsung SSD 860 EVO mSATA 250GB`
- **Serial:** `S41MNB0K308570A`
- **Device:** `/dev/sdb`

```text
/dev/sdb → LUKS → storage-msata (ext4) → /mnt/storage-msata
```

Filesystem label: `storage-msata`

### 3. OCZ Vertex 450 256 GB (USB)

- **Model:** `OCZ-VERTEX450`
- **Serial:** `OCZ-YE4Y536MA71Y30C4`
- **Device:** `/dev/sdc`

```text
/dev/sdc → LUKS → storage-ocz (ext4) → /mnt/storage-ocz
```

Filesystem label: `storage-ocz`

### 4. Samsung PM871a 256 GB (USB)

- **Model:** `SAMSUNG SSD PM871a 2.5 7mm 256GB`
- **Serial:** `S2XNNX0J706836`
- **Device:** `/dev/sdd`

```text
/dev/sdd → LUKS → backups (ext4) → /mnt/backups
```

Filesystem label: `backups`. Reserved for backups only — not general-purpose storage.

> ⚠️ **Note:** USB-connected drive letters (`/dev/sdb`/`sdc`/`sdd`) can shift depending on enumeration order at boot. Always confirm by **model/serial** (`lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS,TRAN`) before acting on a device — mounting itself relies on LUKS UUIDs in `/etc/crypttab`, not device letters, so this only matters for manual operations.

---

## 🔐 Encryption

All four SSDs use **LUKS encryption at rest**.

```text
/dev/sda3 → LUKS → /dev/mapper/sda3_crypt     → ext4 → /
/dev/sdb  → LUKS → /dev/mapper/storage-msata  → ext4 → /mnt/storage-msata
/dev/sdc  → LUKS → /dev/mapper/storage-ocz    → ext4 → /mnt/storage-ocz
/dev/sdd  → LUKS → /dev/mapper/backups        → ext4 → /mnt/backups
```

If a physical SSD is removed from the server, its contents cannot be accessed without the correct LUKS credentials.

---

## 🔑 LUKS Recovery

LUKS headers are backed up for all four encrypted drives. **They are not stored in this Git repository** — they live offline on separate recovery media (ideally more than one location).

Header backups exist for:

```text
Lexar          /dev/sda3
Samsung mSATA  /dev/sdb
OCZ            /dev/sdc
Samsung PM871a /dev/sdd
```

Recovery files: `*.img` (and optionally `*-luks-dump.txt`).

LUKS passphrases are stored separately in a password manager — **never** in this repo.

Restore a header if a device's header becomes corrupted:

```bash
sudo cryptsetup luksHeaderRestore /dev/sdX \
  --header-backup-file /root/luks-headers/device-luks-header.img
```

---

## 📁 Filesystem & Mount Points

| Device | Encryption | Filesystem | Mount Point | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `/dev/sda3` | LUKS | ext4 | `/` | Main OS / Docker |
| `/dev/sdb` | LUKS | ext4 | `/mnt/storage-msata` | Additional storage |
| `/dev/sdc` | LUKS | ext4 | `/mnt/storage-ocz` | Additional storage |
| `/dev/sdd` | LUKS | ext4 | `/mnt/backups` | Backups |

Mounting is driven by `/etc/crypttab` (LUKS UUID → mapper name) and `/etc/fstab` (mapper device → mount point). See [Phase 7](#phase-7--configure-crypttab) for exact setup.

## 🔌 Accessing External USB Drives

```bash
# Identify the drive by model/serial (never trust /dev/sdX alone)
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS,TRAN

# Open (decrypt) the LUKS container
sudo cryptsetup open /dev/sdX storage-name   # use 'backups' for the PM871a

# Mount
sudo mkdir -p /mnt/storage-name
sudo mount /dev/mapper/storage-name /mnt/storage-name

# Verify
lsblk -f
df -h

# When done — unmount and close before disconnecting
sudo umount /mnt/storage-name
sudo cryptsetup close storage-name
```

> If the drive is already in `/etc/crypttab`/`/etc/fstab`, just run `sudo mount /mnt/storage-name` after plugging it in — it'll prompt for the passphrase and mount automatically via its LUKS UUID.

---

## 🌐 Networking

Primary connection: Ethernet (`eno1`).

Remote access is provided exclusively through **Tailscale**. No direct Internet port forwarding is used, and SSH is not exposed directly to the public Internet.

---

## 🔗 Tailscale

Installed natively on Debian. Provides encrypted remote access, MagicDNS, and Tailscale SSH without router port forwarding.

The server's Tailscale IP is in the `100.64.0.0/10` CGNAT range and **can change** if the node is removed/re-added — prefer the MagicDNS hostname over hardcoding the IP in service configs.

Intended remote-admin path:

```text
Laptop / Desktop / Phone → Tailscale → Home Server → Tailscale SSH
```

SSH access is protected via Tailscale identity-based authentication — no password auth, no standard SSH port exposed to the LAN/Internet.

Check status:

```bash
tailscale status
tailscale ip
```

---

## 🐳 Docker

Docker Compose is used for every service (not standalone `docker run`) so configuration is reproducible and portable to another machine/distro.

## 📂 Docker Directory Structure

Docker Compose services are organized into separate directories under `/opt/docker/`. Each service has its own `compose.yaml`.

```text
/opt/docker/
├── adguard/
├── beszel/
├── firefly-iii/
├── nextcloud/
├── portainer/
├── stirling-pdf/
```

---

## 🚀 Currently Running Services

All services are containerized using Docker and Docker Compose, managed behind a strict UFW firewall.

| Service | Category | Deployment | Port | Description |
|---|---|---|---:|---|
| Tailscale | Networking | Native Service | — | Encrypted mesh VPN for secure remote access without open ports |
| AdGuard Home | Network / Security | Docker | — | Network-wide DNS ad-blocking and tracking sinkhole |
| Nextcloud | Cloud & Storage | Docker | `8085` | Self-hosted personal cloud storage, file sync, and backup |
| Beszel | Telemetry / Stats | Docker | `8090` | Lightweight server resource monitoring for CPU, RAM, GPU, temperatures, and Docker |
| Portainer | Management | Docker | `9443` | Web-based management UI for Docker containers, images, volumes, and stacks |
| Stirling PDF | Productivity | Docker | `8080` | Self-hosted web-based PDF toolkit for conversion, editing, merging, splitting, OCR, and other PDF operations |
| Firefly III | Finance | Docker | `8082` | Self-hosted personal finance manager for tracking accounts, transactions, budgets, and expenses |

---

## 🔮 Planned Services

  * [ ] Vaultwarden — self-hosted password manager
  * [ ] Homepage / Dashy — central dashboard for launching all web apps
  * [ ] Joplin — self-hosted notes and to-do application
  * [ ] RSS reader — self-hosted RSS feed aggregation

---

## 💾 Automated Encrypted Backups

The Samsung PM871a is used as an encrypted offline backup drive.

When the drive is unlocked and mounted, `systemd` automatically starts the backup service:

- Docker configuration files
- Nextcloud files and application data
- Nextcloud MariaDB database
- Important system configuration files
- `rsync` is used for incremental backups, so unchanged files are not recopied

### Backup Procedure

Unlock and mount the PM871a:

```bash
sudo cryptsetup open /dev/sdd backups
sudo mount /mnt/backups
```

**That's it.** The backup starts automatically.

Monitor the backup with:

```bash
sudo journalctl -u home-server-backup.service -f
```

When it's finished:

```bash
systemctl status home-server-backup.service --no-pager
```

Then safely disconnect:

```bash
sudo systemctl stop home-server-backup.service
sudo umount /mnt/backups
sudo cryptsetup close backups
```

The PM871a can then be physically disconnected and stored separately.

### Backup Script

The backup script is located at:

```text
/usr/local/sbin/home-server-backup
```

The systemd service is:

```text
/etc/systemd/system/home-server-backup.service
```

---

## 🔒 Security & Optimization Setup

- **Encryption at rest** — all SSDs use LUKS.
- **No public SSH exposure** — remote admin via Tailscale identity-based auth only; no password auth or standard SSH port exposed.
- **Docker isolation** — applications run in containers.
- **Minimal services** — only what's required is installed.
- **Separate backup drive** — PM871a reserved for backups.
- **Offline LUKS recovery** — headers stored away from the server.
- **Secrets excluded from Git** — passwords, API keys, LUKS headers, credentials never committed.
- **Beszel socket interconnect** — Beszel Hub and Agent communicate via a host-mounted Unix socket (`./beszel_socket/beszel.sock`) for firewall-free, zero-latency metric streaming instead of a network port.

### Firewall (UFW)

Default-deny incoming policy. Only Tailscale and the local LAN subnet are allowed in.

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow all traffic over the Tailscale interface
sudo ufw allow in on tailscale0

# Allow local LAN subnet (e.g. for AdGuard DNS serving household devices)
sudo ufw allow from 192.168.0.0/24

sudo ufw enable
sudo ufw status verbose
```

```text
Internet ──X── No direct inbound access
Tailscale ──▶ Home Server
LAN (192.168.0.0/24) ──▶ Home Server (limited, e.g. DNS only)
```

> ⚠️ **Docker bypasses UFW by default.** Containers with published ports (`-p 8080:8080`) can be reachable from the LAN even with a UFW deny rule in place, because Docker manipulates iptables/nftables directly. Mitigate by binding container ports to `127.0.0.1:8080:8080` (only reachable via reverse proxy/Tailscale) or by using `ufw-docker` to reconcile the two.

### Access Control (ACL)

UFW's source-based allow rules function as the access control layer here — no separate ACL system is used:

- **Tailscale (`tailscale0`)** — full access, identity-authenticated per-device via the tailnet
- **LAN (`192.168.0.0/24`)** — limited access (e.g. AdGuard DNS only)
- **Everything else** — denied by default

### Wi-Fi / Bluetooth (disabled)

The server doesn't need wireless radios — they're disabled to reduce attack surface and power draw.

Quick/runtime disable:

```bash
sudo rfkill block wifi
sudo rfkill block bluetooth
rfkill list   # verify
```

Persistent disable (blacklist the kernel modules so they never load):

```bash
sudo nano /etc/modprobe.d/blacklist-radios.conf
```

```text
blacklist iwlwifi
blacklist btusb
blacklist bluetooth
```

```bash
sudo systemctl disable bluetooth
sudo update-initramfs -u
sudo reboot
```

Verify after reboot:

```bash
lsmod | grep -E 'iwlwifi|bluetooth'   # should return nothing
```

---

## ⚡ Power Management

The server is a laptop (Dell Precision M4800) run headless. Goals: stay powered with the lid closed, minimize idle draw, avoid unintended suspend, keep networking and Docker running.

### Lid behavior

Closing the lid does not suspend or power off the server; Docker and Tailscale keep running. Configured via `/etc/systemd/logind.conf`:

```text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

### Idle power tuning

```bash
sudo apt install powertop tlp tlp-rdw
sudo systemctl enable tlp --now
sudo powertop --auto-tune
```

Check current TLP settings and CPU governor:

```bash
sudo tlp-stat -p
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
```

`powersave` is preferred for a mostly-idle server; switch to `performance` only for CPU-bound workloads.

### Discrete GPU disabled

The M4800's discrete NVIDIA GPU is blacklisted since it's unused, eliminating its power draw:

```bash
sudo nano /etc/modprobe.d/blacklist-nvidia.conf
```

```text
blacklist nouveau
blacklist nvidia
options nvidia-drm modeset=0
```

```bash
sudo update-initramfs -u
sudo reboot
```

Verify:

```bash
lspci -k | grep -A3 VGA
nvidia-smi   # should fail / not found if properly disabled
```

### Radios disabled

Wi-Fi and Bluetooth are disabled via `rfkill` — see [Wi-Fi / Bluetooth](#wi-fi--bluetooth-disabled) above.

---

## 🔄 Rebuild Procedure

Goal: rebuild the server from scratch without depending on undocumented manual changes.

### Phase 1 — Install Debian

- Install Debian 13 (Trixie), UEFI boot.
- Use the **Lexar 512 GB SSD** as the primary system disk.
- Enable full-disk LUKS encryption for the Linux system partition.
- Do **not** include the additional SSDs in the installation.

Expected result:

```text
/dev/sda
├── EFI
├── /boot
└── LUKS → /
```

### Phase 2 — First Boot

```bash
sudo apt update
sudo apt full-upgrade
sudo apt install curl wget git vim htop smartmontools cryptsetup ufw powertop tlp tlp-rdw
lsblk -f
```

### Phase 3 — Configure Lid Behavior

```bash
sudo nano /etc/systemd/logind.conf
```

Set:

```text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

Restart logind (or reboot) and verify the server stays up with the lid closed.

### Phase 4 — Install Tailscale

Install, authenticate to the tailnet, verify:

```bash
tailscale status
```

Enable Tailscale SSH and verify remote access **before** proceeding further — you want a remote path into the machine early in a rebuild.

### Phase 5 — Prepare Additional SSDs

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS,TRAN
```

Never rely on `/dev/sdb`/`sdc`/etc. alone — verify model + serial against the [Disk Layout](#-disk-layout) table before formatting anything.

### Phase 6 — Configure LUKS

```bash
sudo cryptsetup luksFormat /dev/sdX
sudo cryptsetup open /dev/sdX storage-name
sudo mkfs.ext4 -L storage-name /dev/mapper/storage-name
sudo mkdir -p /mnt/storage-name
sudo mount /dev/mapper/storage-name /mnt/storage-name
lsblk -f
df -h
```

### Phase 7 — Configure crypttab

Use LUKS UUIDs, not device names.

```bash
sudo blkid
sudo cryptsetup luksUUID /dev/sdX
```

Add entries to `/etc/crypttab`, then configure `/etc/fstab` for the decrypted filesystems.

```bash
sudo systemctl daemon-reload
```

Test a reboot to confirm everything mounts automatically (you'll be prompted for LUKS passphrases at boot).

### Phase 8 — Create LUKS Header Backups

```bash
sudo mkdir -p /root/luks-headers
sudo chmod 700 /root/luks-headers
sudo cryptsetup luksHeaderBackup /dev/sdX \
  --header-backup-file /root/luks-headers/device-luks-header.img
sudo ls -lh /root/luks-headers
```

Copy these to offline recovery media. **Never commit to Git.**

### Phase 9 — Install Docker

```bash
docker --version
docker compose version
sudo mkdir -p /opt/docker
sudo chown -R $USER:$USER /opt/docker
```

### Phase 10 — Docker Directory Structure

```bash
mkdir -p /opt/docker/{nextcloud,adguard,beszel,portainer,ntfy,uptime-kuma}
```

### Phase 11 — Deploy Core Services

Create a `compose.yaml` per service under its own directory. Keep secrets in a local `.env` (gitignored), e.g.:

```text
MYSQL_ROOT_PASSWORD=<secret>
MYSQL_PASSWORD=<secret>
```

```bash
cd /opt/docker/<service>
docker compose up -d
docker compose ps
docker compose logs
```

For Nextcloud, configure trusted domains to match how you actually access it (localhost, Tailscale IP, MagicDNS hostname):

```bash
docker exec -u www-data nextcloud php occ config:system:get trusted_domains
```

For AdGuard Home, only point network DNS at it after confirming it's working correctly — a broken DNS server can take down your whole LAN's internet access.

Portainer should be verified reachable only via the trusted network/Tailscale — never expose it publicly.

### Phase 12 — Configure Firewall, Radios, and Power

- Set up UFW per [Firewall (UFW)](#firewall-ufw) above.
- Disable Wi-Fi/Bluetooth per [Wi-Fi / Bluetooth](#wi-fi--bluetooth-disabled) above.
- Apply power tuning per [Power Management](#-power-management) above.

### Phase 13 — Verify Everything

```bash
docker ps
lsblk -f      # all expected encrypted drives present
df -h         # all expected mount points present
tailscale status
sudo ufw status verbose
rfkill list
```

---

## ➕ Adding More Storage Later

The architecture is designed so storage can expand without reinstalling Debian:

```text
New SSD → LUKS → ext4 → /mnt/new-storage
```

1. Physically install the drive
2. Identify it (`lsblk -o NAME,SIZE,MODEL,SERIAL,...`)
3. Encrypt with LUKS
4. Format ext4
5. Add to `/etc/crypttab`
6. Add to `/etc/fstab`
7. Mount
8. Assign to applications as needed

No RAID rebuild, no LVM expansion, no reinstall required. This is the main reason a multi-disk pool was avoided.

---

## 🛟 Recovery Procedure

**Main system SSD fails:**

1. Replace the SSD.
2. Install Debian, recreate the encrypted system (see [Rebuild Procedure](#-rebuild-procedure)).
3. Restore Docker configuration from this repository.
4. Restore application data from backup (`/mnt/backups`).
5. Reconfigure Tailscale.
6. Restore Nextcloud, verify all services.

**Additional storage SSD fails:**

1. Replace the failed SSD.
2. Create a new LUKS container + ext4 filesystem.
3. Configure `/etc/crypttab` and `/etc/fstab`.
4. Restore data from backups.

No individual additional-SSD failure should require reinstalling the entire server.

---

## 🧩 Troubleshooting

Quick pointers for common issues — expand this section as real problems come up.

| Symptom | Check |
| :--- | :--- |
| Server won't boot / hangs at LUKS prompt | Confirm correct passphrase; if header is suspected corrupt, restore from `/root/luks-headers/*.img` (see [LUKS Recovery](#-luks-recovery)) |
| A `/mnt/*` mount is missing after reboot | `sudo cryptsetup status <name>`, check `/etc/crypttab` and `/etc/fstab` entries, check `journalctl -b` for mount errors |
| USB drive not detected consistently | Check cable/port, `dmesg \| tail`, confirm it still enumerates by serial via `lsblk -o NAME,SERIAL,TRAN` |
| Docker service unreachable | `docker compose ps`, `docker compose logs`, confirm container is on expected network/port |
| Service reachable on LAN despite UFW deny | Check for a Docker-published port bypassing UFW — bind to `127.0.0.1` or use `ufw-docker` |
| Can't reach a service over Tailscale | `tailscale status`, confirm MagicDNS hostname resolves, check the service isn't bound to `127.0.0.1` only when it needs Tailscale access |
| Nextcloud "untrusted domain" error | Check/update `trusted_domains` via `occ` (see Phase 11) |
| AdGuard breaks DNS network-wide | Point a test client back to a public resolver temporarily, fix AdGuard config, re-point DNS once confirmed working |
| Disk seems to be failing | `sudo smartctl -a /dev/sdX` (for USB-SATA bridges you may need `-d sat` or similar to get correct SMART data) |
| Lid closing suspends the server unexpectedly | Re-check `/etc/systemd/logind.conf` values, confirm `systemctl restart systemd-logind` was applied |
| Wi-Fi/Bluetooth re-appears after a kernel update | Re-check `/etc/modprobe.d/blacklist-radios.conf` and re-run `update-initramfs -u` |

---

## 🧪 Useful Commands

```bash
# Disks
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS,TRAN
lsblk -f
sudo blkid
findmnt
df -h

# LUKS
sudo cryptsetup status <name>
sudo cryptsetup luksUUID /dev/sdX
sudo cryptsetup luksDump /dev/sdX

# SMART
sudo smartctl -a /dev/sdX

# Docker
docker ps
docker compose ps
docker compose logs

# Tailscale
tailscale status
tailscale ip

# Firewall
sudo ufw status verbose

# Radios / Power
rfkill list
sudo tlp-stat -p
```

---

## 🚫 Secrets Policy

Never commit to this repository:

```text
Passwords
LUKS passphrases
LUKS header backups (*.img)
.env files containing secrets
API keys
Tailscale authentication keys
Private SSH keys
TLS private keys
Nextcloud private data
Database dumps containing sensitive information
Personal photos/videos
```

`.gitignore`:

```gitignore
.env
.env.*
*.key
*.pem
*.secret
*.img
secrets/
luks-headers/
backup/
backups/
```

---



## 📅 Installation History

### 2026-08-11 — Server Rebuild

- Fresh Debian 13 installation
- Lexar 512 GB SSD selected as primary system drive
- Full-disk LUKS encryption enabled on the system
- Samsung 860 EVO mSATA, OCZ Vertex 450, and Samsung PM871a configured with LUKS + ext4
- PM871a reserved for backups
- Additional SSDs mounted independently
- Docker + Tailscale (with Tailscale SSH) installed
- Nextcloud deployment started
- Docker Compose adopted as the standard deployment method
- LUKS headers backed up to offline recovery media
- UFW firewall configured (Tailscale + LAN subnet only)
- Wi-Fi, Bluetooth, and discrete GPU disabled for power efficiency
- Uptime Kuma, ntfy, Beszel, and Portainer deployed for monitoring/management

---

## 📜 License

This repository contains personal documentation and configuration examples for my home server. Unless otherwise specified, the documentation is licensed under the MIT License. See `LICENSE` for details.
