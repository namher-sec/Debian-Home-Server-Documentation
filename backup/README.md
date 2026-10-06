## 💾 Automated Encrypted Backups

The Samsung PM871a is used as an encrypted offline backup drive.

Backups are managed by **Restic** and stored in an encrypted Restic repository on the LUKS-encrypted drive.

The backup includes:

- Docker configuration and persistent data
- Nextcloud files and application data
- Nextcloud database
- System configuration
- User and root files
- Custom system files and scripts

Restic provides:

- Incremental backups
- Content-based deduplication
- Encryption
- Snapshots
- Integrity checking
- Efficient storage of changed data

### Backup Procedure

Unlock and mount the PM871a:

```bash
sudo cryptsetup open /dev/sdd backups
sudo mount /mnt/backups
```

Start the backup service:

```bash
sudo systemctl start home-server-backup.service
```

The service automatically:

1. Enables Nextcloud maintenance mode
2. Runs the Restic backup
3. Disables Nextcloud maintenance mode

Monitor the backup with:

```bash
sudo journalctl -u home-server-backup.service -f
```

When it's finished:

```bash
systemctl status home-server-backup.service --no-pager
```

Verify the available snapshots:

```bash
sudo sh -c '
set -a
. /etc/restic-home-server.env
set +a
restic snapshots
'
```

Then safely disconnect:

```bash
sudo umount /mnt/backups
sudo cryptsetup close backups
```

The PM871a can then be physically disconnected and stored separately.

### Backup Service

The systemd service is located at:

```text
/etc/systemd/system/home-server-backup.service
```

The Restic configuration is located at:

```text
/etc/restic-home-server.env
```

The Restic repository is stored at:

```text
/mnt/backups/restic
```

The Restic repository password is stored separately at:

```text
/root/.config/restic/password
```

**Keep the Restic repository password safe. Without it, the encrypted backup cannot be recovered.**

### Verify Backup Integrity

To check the integrity of the Restic repository:

```bash
sudo sh -c '
set -a
. /etc/restic-home-server.env
set +a
restic check
'
```
