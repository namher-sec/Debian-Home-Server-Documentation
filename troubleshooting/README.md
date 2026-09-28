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

| Issue | Resolution |
|---|---|
| Caddy returns `502 Bad Gateway` | Check that the backend container is running and connected to `caddy_proxy`; verify the backend name/port in the Caddyfile |
| Vaultwarden cannot be reached | Check `docker ps`, `docker network inspect caddy_proxy`, and Caddy logs |
| Caddy configuration changed but old behavior remains | Validate the Caddyfile and reload Caddy with `caddy reload` |
| HTTPS hostname does not resolve | Verify Tailscale is running and MagicDNS is enabled; confirm the server's Tailscale hostname with `tailscale status` |
| Vaultwarden registration should remain disabled | Verify the Vaultwarden registration setting/environment configuration |
| Vaultwarden is accidentally exposed on a host port | Check `docker ps` and the Vaultwarden Compose file; remove unnecessary `ports:` mappings |
| Uptime Kuma cannot monitor AdGuard DNS | Verify AdGuard itself with `dig @192.168.0.10 google.com`. If the host can query AdGuard but a Docker container cannot, check UFW. Docker bridge traffic originates from the Docker subnet (e.g. `172.22.0.0/16`) and was blocked by the default `deny (routed)` / host firewall policy. Allow DNS traffic from the relevant Docker subnet on UDP/TCP port 53. |


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
```bash
# Caddy
cd /opt/docker/caddy
sudo docker compose ps
sudo docker compose logs --tail 50
sudo docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
sudo docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
 
# Reverse proxy network
sudo docker network inspect caddy_proxy
 
# Vaultwarden
cd /opt/docker/vaultwarden
sudo docker compose ps
sudo docker compose logs --tail 50
```


---

