# DNS Fix: AdGuard Home + Tailscale + Docker

## Problem

The server could not resolve its Tailscale hostname:

```text
debianhomeserver.tail156611.ts.net
```

Normal DNS returned `NXDOMAIN`, while Tailscale itself could resolve the hostname.
This also prevented Docker containers such as Uptime Kuma from resolving the Tailscale hostname.

## What Was Changed

### 1. AdGuard Home

Added a domain-specific upstream DNS rule:

```text
[/tail156611.ts.net/]100.100.100.100
```

This sends Tailscale `.ts.net` queries to Tailscale's local MagicDNS resolver.

### 2. Tailscale

Disabled Tailscale from managing the system DNS configuration:

```bash
sudo tailscale set --accept-dns=false
```

### 3. systemd-resolved

Configured `systemd-resolved` to use AdGuard Home:

```ini
# /etc/systemd/resolved.conf.d/adguard.conf

[Resolve]
DNS=127.0.0.1
```

Enabled the service:

```bash
sudo systemctl enable --now systemd-resolved
```

### 4. /etc/resolv.conf

Replaced the existing file with the `systemd-resolved` stub resolver:

```bash
sudo cp -L /etc/resolv.conf /etc/resolv.conf.backup
sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

Restarted DNS services:

```bash
sudo systemctl restart systemd-resolved
sudo systemctl restart tailscaled
```

After restarting Tailscale, make sure DNS management remains disabled:

```bash
sudo tailscale set --accept-dns=false
```

### 5. Docker / Uptime Kuma

Configured Uptime Kuma to use Tailscale's DNS resolver directly:

```yaml
dns:
  - 100.100.100.100
```

## Verification

Check the system resolver:

```bash
resolvectl status
```

Expected global DNS:

```text
DNS Servers: 127.0.0.1
```

Test normal DNS:

```bash
getent hosts google.com
```

Test the Tailscale hostname:

```bash
getent hosts debianhomeserver.tail156611.ts.net
```

Expected:

```text
100.98.146.80 debianhomeserver.tail156611.ts.net
```

Test directly through Tailscale:

```bash
sudo tailscale dns query debianhomeserver.tail156611.ts.net
```

Test from Uptime Kuma:

```bash
docker exec uptimekuma-uptime-kuma-1 \
  getent hosts debianhomeserver.tail156611.ts.net
```

## Result

DNS now works through the following path:

```text
Application
    ↓
systemd-resolved
    ↓
AdGuard Home
    ├── Normal domains → configured upstream DNS
    └── *.tail156611.ts.net → 100.100.100.100
                                      ↓
                                  Tailscale MagicDNS
```

The Tailscale DNS warning was also resolved, and Docker containers can resolve the server's private Tailscale hostname.
