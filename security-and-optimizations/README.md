## 🔒 Security & Optimization Setup

- **Encryption at rest** — all SSDs use LUKS.
- **No public SSH exposure** — remote admin via Tailscale identity-based auth only; no password auth or standard SSH port exposed.
- **Docker isolation** — applications run in containers.
- **Minimal services** — only what's required is installed.
- **Separate backup drive** — PM871a reserved for backups.
- **Offline LUKS recovery** — headers stored away from the server.
- **Secrets excluded from Git** — passwords, API keys, LUKS headers, credentials never committed.
- **Beszel socket interconnect** — Beszel Hub and Agent communicate via a host-mounted Unix socket (`./beszel_socket/beszel.sock`) for firewall-free, zero-latency metric streaming instead of a network port.
- **Reverse proxy isolation** — Vaultwarden is not directly published to a host port; Caddy accesses it through the dedicated `caddy_proxy` Docker network.
- **HTTPS** — Vaultwarden traffic is encrypted using HTTPS through Caddy.
- **Tailscale-only access** — Vaultwarden is accessible through the server's Tailscale hostname without router port forwarding.
- **Registration disabled** — Vaultwarden account registration is disabled after the initial account was created.
- **Minimal proxy exposure** — Caddy exposes HTTPS on port `443`; backend application ports remain internal where possible.
- **Separate Docker network** — Caddy and proxied applications communicate through the dedicated `caddy_proxy` network.

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

