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
