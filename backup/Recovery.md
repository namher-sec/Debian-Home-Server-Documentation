# Restore the Entire Server

If the server's OS or disk completely dies:

### 1. Reinstall Debian

Install a fresh Debian system.

### 2. Install Restic

```bash
sudo apt update
sudo apt install restic cryptsetup

```

### 3. Connect the Backup Drive

Identify the encrypted partition:

```bash
lsblk -f

```

Look for the partition with the `crypto_LUKS` filesystem type.

### 4. Unlock LUKS

```bash
sudo cryptsetup open /dev/sdX backups

```

Replace `/dev/sdX` with the actual encrypted partition.

Enter the LUKS password when prompted.

### 5. Mount the Backup Drive

```bash
sudo mkdir -p /mnt/backups
sudo mount /dev/mapper/backups /mnt/backups

```

Verify the mount:

```bash
findmnt /mnt/backups

```

### 6. Verify the Restic Repository

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic snapshots

```

Enter the Restic repository password when prompted.

The available snapshots should be displayed.

### 7. Restore the Backup

For a complete server restoration:

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target /

```

> **Warning:** This should only be done on a fresh/replacement system. It restores files to their original filesystem paths and should not be performed on the currently running server unless you specifically intend to overwrite existing files.

For a controlled recovery, restore to a temporary directory first:

```bash
sudo mkdir -p /tmp/server-restore

sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target /tmp/server-restore

```

The restored files will be available under:

`/tmp/server-restore/`

You can then selectively restore the required files to their original locations.

---

# Restore Only Important Server Components

You do not necessarily need to restore the entire server. Individual components can be restored from the latest snapshot.

### Docker Configuration

Restore the Docker configuration and Compose files:

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target / \
    --include '/opt/docker'

```

### Docker Persistent Volumes

Restore persistent Docker application data:

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target / \
    --include '/var/lib/docker/volumes'

```

### System Configuration

Restore system configuration:

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target / \
    --include '/etc'

```

### Home Directory

Restore user files:

```bash
sudo env RESTIC_REPOSITORY=/mnt/backups/restic restic restore latest \
    --target / \
    --include '/home'

```

---

## After Restoration

Once the required files have been restored and you are finished using the backup drive, unmount it:

```bash
sudo umount /mnt/backups

```

Then lock the LUKS container:

```bash
sudo cryptsetup close backups

```

Verify that the filesystem is no longer mounted:

```bash
findmnt /mnt/backups

```

There should be no output.

Verify that the LUKS mapping is closed:

```bash
ls /dev/mapper/backups

```

It should report that the device does not exist.

The backup drive can then be physically disconnected and stored separately.

---

## Recovery Requirements

A complete recovery requires:

* The encrypted backup drive
* The LUKS password
* The Restic repository password

The Restic repository password is required to decrypt the backup data. Keep it stored separately from the backup drive.
