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

## Disk Layout

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
