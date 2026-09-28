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

### Phase 11A — Configure Caddy Reverse Proxy
 
Create the shared Docker network:
 
```bash
sudo docker network create caddy_proxy
```
 
Deploy Caddy:
 
```bash
cd /opt/docker/caddy
sudo docker compose up -d
```
 
Verify:
 
```bash
sudo docker compose ps
sudo docker logs caddy --tail 50
```
 
Create the Caddy configuration:
 
```text
/opt/docker/caddy/conf/Caddyfile
```
 
Example:
 
```caddyfile
<your-server>.tail<tailnet-id>.ts.net{
    reverse_proxy vaultwarden:80
}
```
 
Validate:
 
```bash
sudo docker compose exec caddy \
    caddy validate --config /etc/caddy/Caddyfile
```
 
Reload:
 
```bash
sudo docker compose exec caddy \
    caddy reload --config /etc/caddy/Caddyfile
```
 
### Phase 11B — Deploy Vaultwarden
 
Deploy Vaultwarden separately:
 
```bash
cd /opt/docker/vaultwarden
sudo docker compose up -d
```
 
Connect Vaultwarden to the shared Caddy network:
 
```yaml
networks:
  caddy_proxy:
    external: true
```
 
and:
 
```yaml
services:
  vaultwarden:
    networks:
      - caddy_proxy
```
 
Verify that both containers are connected:
 
```bash
sudo docker network inspect caddy_proxy
```
 
Expected:
 
```text
caddy
vaultwarden
```
 
Vaultwarden should not need a published host port when Caddy is used as the reverse proxy.
 
Verify HTTPS access through:
 
```text
<your-server>.tail<tailnet-id>.ts.net
```
 
After the initial Vaultwarden account is created and configured, disable public registration.

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
