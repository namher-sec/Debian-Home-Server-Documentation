#!/bin/bash

# Home Server Backup
# Automatically backs up Docker configuration, Nextcloud,
# MariaDB, and selected Debian system configuration.
#
# Intended for use with an encrypted external backup disk
# mounted at /mnt/backups.
#
# Requirements:
#   - bash
#   - rsync
#   - docker
#   - cryptsetup
#   - gzip
#   - util-linux

set -Eeuo pipefail

============================================================

HOME SERVER BACKUP

============================================================



Backup destination:

/mnt/backups/server-backup



Backup source:

/opt/docker

Nextcloud Docker volume

/opt/docker/nextcloud/data

MariaDB database

Important Debian configuration



Designed to run after the encrypted PM871a is unlocked

and mounted at /mnt/backups.



Subsequent file backups are incremental through rsync.



============================================================

------------------------------------------------------------

Configuration

------------------------------------------------------------

BACKUP_MOUNT="/mnt/backups"BACKUP_ROOT="${BACKUP_MOUNT}/server-backup"

DOCKER_SOURCE="/opt/docker"DOCKER_DEST="${BACKUP_ROOT}/docker"

NEXTCLOUD_DEST="${BACKUP_ROOT}/nextcloud"NEXTCLOUD_VOLUME_DEST="${NEXTCLOUD_DEST}/application"NEXTCLOUD_DATA_DEST="${NEXTCLOUD_DEST}/data"DATABASE_DEST="${NEXTCLOUD_DEST}/database"

SYSTEM_DEST="${BACKUP_ROOT}/system"

LOG_FILE="${BACKUP_ROOT}/backup.log"

LOCK_FILE="/run/home-server-backup.lock"

NEXTCLOUD_CONTAINER="nextcloud"DB_CONTAINER="nextcloud-db"

Keep this many database dumps.

DB_RETENTION=8

Minimum free space required before starting.

MIN_FREE_GB=5

MAINTENANCE_ENABLED=0

------------------------------------------------------------

Logging

------------------------------------------------------------

log() {echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"}

------------------------------------------------------------

Cleanup

------------------------------------------------------------

cleanup() {

if [[ "${MAINTENANCE_ENABLED:-0}" -eq 1 ]]; then

    log "Cleanup: disabling Nextcloud maintenance mode..."

    if docker exec \
        -u www-data \
        "$NEXTCLOUD_CONTAINER" \
        php occ maintenance:mode --off; then

        log "Nextcloud maintenance mode disabled."

    else

        log "WARNING: Could not disable Nextcloud maintenance mode."
        log "CHECK NEXTCLOUD MANUALLY."

    fi
fi

rm -f "$LOCK_FILE"

}

trap cleanup EXIT

------------------------------------------------------------

Error handler

------------------------------------------------------------

error_handler() {

local exit_code=$?

log ""
log "============================================================"
log "BACKUP FAILED"
log "Exit code: $exit_code"
log "============================================================"

exit "$exit_code"

}

trap error_handler ERR

------------------------------------------------------------

Must run as root

------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then

echo "ERROR: Run this script with sudo."

exit 1

fi

------------------------------------------------------------

SAFETY CHECK



/mnt/backups MUST actually be mounted.

This prevents accidentally writing backups onto the Lexar

root filesystem if the PM871a is disconnected.

------------------------------------------------------------

if ! mountpoint -q "$BACKUP_MOUNT"; then

echo ""
echo "ERROR:"
echo "$BACKUP_MOUNT is NOT mounted."
echo ""
echo "Backup aborted for safety."
echo ""

exit 1

fi

------------------------------------------------------------

Determine actual mounted device

------------------------------------------------------------

BACKUP_DEVICE="$(findmnt -n -o SOURCE --target "$BACKUP_MOUNT")"

if [[ -z "$BACKUP_DEVICE" ]]; then

echo "ERROR: Could not determine backup device."

exit 1

fi

------------------------------------------------------------

Root filesystem safety check

------------------------------------------------------------

ROOT_DEVICE="$(findmnt -n -o SOURCE /)"

if [[ "$BACKUP_DEVICE" == "$ROOT_DEVICE" ]]; then

echo ""
echo "CRITICAL ERROR:"
echo "Backup destination appears to be the root filesystem."
echo ""
echo "Backup aborted."
echo ""

exit 1

fi

------------------------------------------------------------

Lock

------------------------------------------------------------

exec 9>"$LOCK_FILE"

if ! flock -n 9; then

echo "Another backup is already running."

exit 1

fi

------------------------------------------------------------

Create directories

------------------------------------------------------------

mkdir -p "$DOCKER_DEST"mkdir -p "$NEXTCLOUD_VOLUME_DEST"mkdir -p "$NEXTCLOUD_DATA_DEST"mkdir -p "$DATABASE_DEST"mkdir -p "$SYSTEM_DEST"

------------------------------------------------------------

Start logging

------------------------------------------------------------

exec > >(tee -a "$LOG_FILE") 2>&1

log "============================================================"log "HOME SERVER BACKUP STARTED"log "============================================================"

log "Backup device : $BACKUP_DEVICE"log "Backup mount  : $BACKUP_MOUNT"log "Backup root   : $BACKUP_ROOT"

------------------------------------------------------------

Check free space

------------------------------------------------------------

AVAILABLE_KB="$(df -Pk "$BACKUP_MOUNT" |awk 'NR==2 {print $4}')"

MIN_FREE_KB=$((MIN_FREE_GB * 1024 * 1024))

if (( AVAILABLE_KB < MIN_FREE_KB )); then

log "ERROR: Less than ${MIN_FREE_GB} GB free."

exit 1

fi

log "Free space check: OK"

============================================================

1. DOCKER CONFIGURATION

============================================================

log ""log "============================================================"log "1/7 - BACKING UP DOCKER CONFIGURATION"log "============================================================"

if [[ -d "$DOCKER_SOURCE" ]]; then

rsync \
    -aHAX \
    --delete \
    "$DOCKER_SOURCE/" \
    "$DOCKER_DEST/"

log "Docker configuration backup complete."

else

log "WARNING: $DOCKER_SOURCE does not exist."

fi

============================================================

2. DISCOVER NEXTCLOUD VOLUME

============================================================

log ""log "============================================================"log "2/7 - LOCATING NEXTCLOUD STORAGE"log "============================================================"

if ! docker container inspect "$NEXTCLOUD_CONTAINER" >/dev/null 2>&1; then

log "ERROR: Nextcloud container does not exist."

exit 1

fi

NEXTCLOUD_VOLUME_SOURCE="$(docker inspect "$NEXTCLOUD_CONTAINER" --format '{{range .Mounts}}{{if and (eq .Type "volume") (eq .Destination "/var/www/html")}}{{.Source}}{{end}}{{end}}')"

if [[ -z "$NEXTCLOUD_VOLUME_SOURCE" ]]; then

log "ERROR: Could not locate Nextcloud application volume."

exit 1

fi

log "Nextcloud application volume:"log "$NEXTCLOUD_VOLUME_SOURCE"

============================================================

3. NEXTCLOUD MAINTENANCE MODE

============================================================

log ""log "============================================================"log "3/7 - ENABLING NEXTCLOUD MAINTENANCE MODE"log "============================================================"

if ! docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ maintenance:mode --on; then

log "ERROR: Could not enable Nextcloud maintenance mode."

exit 1

fi

MAINTENANCE_ENABLED=1

log "Nextcloud maintenance mode enabled."

============================================================

4. NEXTCLOUD FILES

============================================================

log ""log "============================================================"log "4/7 - BACKING UP NEXTCLOUD FILES"log "============================================================"

if [[ ! -d "/opt/docker/nextcloud/data" ]]; then

log "ERROR: Nextcloud data directory does not exist."

exit 1

fi

rsync -aHAX --delete "/opt/docker/nextcloud/data/" "$NEXTCLOUD_DATA_DEST/"

log "Nextcloud user data backup complete."

============================================================

5. NEXTCLOUD APPLICATION / CONFIGURATION

============================================================

log ""log "============================================================"log "5/7 - BACKING UP NEXTCLOUD APPLICATION DATA"log "============================================================"

The Docker volume contains /var/www/html.



The actual user data is mounted separately at:



/opt/docker/nextcloud/data



Therefore exclude the volume's "data" directory here.

We already backed it up above.

rsync -aHAX --delete --exclude='data/' "$NEXTCLOUD_VOLUME_SOURCE/" "$NEXTCLOUD_VOLUME_DEST/"

log "Nextcloud application/configuration backup complete."

============================================================

6. MARIADB DATABASE

============================================================

log ""log "============================================================"log "6/7 - BACKING UP NEXTCLOUD DATABASE"log "============================================================"

if ! docker container inspect "$DB_CONTAINER" >/dev/null 2>&1; then

log "ERROR: Database container does not exist."

exit 1

fi

Read database configuration from the container.

DB_NAME="$(docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' |sed -n 's/^MYSQL_DATABASE=//p' |head -n1)"

DB_USER="$(docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' |sed -n 's/^MYSQL_USER=//p' |head -n1)"

DB_PASSWORD="$(docker inspect "$DB_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' |sed -n 's/^MYSQL_PASSWORD=//p' |head -n1)"

if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then

log "ERROR: Could not determine MariaDB credentials."

exit 1

fi

log "Database: $DB_NAME"log "Database user: $DB_USER"

DB_TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"

DB_FILE="${DATABASE_DEST}/nextcloud-${DB_TIMESTAMP}.sql.gz"

log "Creating database dump..."

docker exec "$DB_CONTAINER" sh -c 'exec mariadb-dump --single-transaction --default-character-set=utf8mb4 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' | gzip > "$DB_FILE"

if [[ ! -s "$DB_FILE" ]]; then

log "ERROR: Database dump is empty."

rm -f "$DB_FILE"

exit 1

fi

log "Database dump created:"log "$DB_FILE"

Latest database dump

ln -sfn "$(basename "$DB_FILE")" "${DATABASE_DEST}/latest.sql.gz"

------------------------------------------------------------

Database retention

------------------------------------------------------------

log "Applying database retention policy..."

mapfile -t DB_DUMPS < <(find "$DATABASE_DEST" -maxdepth 1 -type f -name 'nextcloud-*.sql.gz' -printf '%T@ %p\n' |sort -rn |awk '{print $2}')

if (( ${#DB_DUMPS[@]} > DB_RETENTION )); then

for ((i=DB_RETENTION; i<${#DB_DUMPS[@]}; i++)); do

    log "Removing old database dump:"
    log "${DB_DUMPS[$i]}"

    rm -f "${DB_DUMPS[$i]}"

done

fi

log "Database retention complete."

============================================================

7. SYSTEM CONFIGURATION / METADATA

============================================================

log ""log "============================================================"log "7/7 - BACKING UP SYSTEM CONFIGURATION"log "============================================================"

SYSTEM_FILES=(

"/etc/fstab"
"/etc/crypttab"
"/etc/hostname"
"/etc/hosts"
"/etc/ssh/sshd_config"
"/etc/systemd/logind.conf"

)

for FILE in "${SYSTEM_FILES[@]}"; do

if [[ -f "$FILE" ]]; then

    DEST="${SYSTEM_DEST}${FILE}"

    mkdir -p "$(dirname "$DEST")"

    cp -a "$FILE" "$DEST"

    log "Backed up: $FILE"

fi

done

------------------------------------------------------------

Installed packages

------------------------------------------------------------

dpkg-query -W -f='${binary:Package}\t${Version}\n' > "${SYSTEM_DEST}/installed-packages.txt"

------------------------------------------------------------

Storage information

------------------------------------------------------------

lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS,TRAN > "${SYSTEM_DEST}/lsblk.txt"

blkid > "${SYSTEM_DEST}/blkid.txt"

------------------------------------------------------------

LUKS information



This is metadata only.

LUKS header images are intentionally NOT copied here.

------------------------------------------------------------

for MAPPING in sda3_crypt storage-msata storage-ocz backupsdo

cryptsetup status "$MAPPING" \
    > "${SYSTEM_DEST}/cryptsetup-${MAPPING}.txt" \
    2>/dev/null || true

done

------------------------------------------------------------

Tailscale

------------------------------------------------------------

if command -v tailscale >/dev/null 2>&1; then

tailscale status \
    > "${SYSTEM_DEST}/tailscale-status.txt" \
    2>&1 || true

tailscale ip \
    > "${SYSTEM_DEST}/tailscale-ip.txt" \
    2>&1 || true

fi

------------------------------------------------------------

Docker information

------------------------------------------------------------

docker ps -a > "${SYSTEM_DEST}/docker-containers.txt"

docker volume ls > "${SYSTEM_DEST}/docker-volumes.txt"

docker network ls > "${SYSTEM_DEST}/docker-networks.txt"

============================================================

FINAL SYNC

============================================================

log ""log "============================================================"log "FINAL SYNC"log "============================================================"

sync

============================================================

Disable maintenance mode

============================================================

log ""log "Disabling Nextcloud maintenance mode..."

if docker exec -u www-data "$NEXTCLOUD_CONTAINER" php occ maintenance:mode --off; then

MAINTENANCE_ENABLED=0

log "Nextcloud is back online."

else

log "WARNING: Could not disable Nextcloud maintenance mode."

log "The cleanup handler will attempt this again."

fi

============================================================

FINAL REPORT

============================================================

log ""log "============================================================"log "BACKUP COMPLETED SUCCESSFULLY"log "============================================================"

log "Backup location:"log "$BACKUP_ROOT"

log ""log "Backup disk:"

df -h "$BACKUP_MOUNT"

log ""log "Backup size:"

du -sh "$BACKUP_ROOT"

log ""log "Finished:"log "$(date '+%Y-%m-%d %H:%M:%S')"

log ""log "============================================================"
