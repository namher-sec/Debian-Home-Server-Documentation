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

## 🔒 Caddy + HTTPS
 
[Caddy](https://caddyserver.com/) is used as a reverse proxy for Vaultwarden.
 
The current setup uses the server's Tailscale MagicDNS hostname:
 
```text
<your-server>.tail<tailnet-id>.ts.net
```
 
Caddy terminates HTTPS and forwards the request internally to the Vaultwarden container over the Docker network.
 
### Architecture
 
```text
Client
   │
   │ Tailscale
   ▼
<your-server>.tail<tailnet-id>.ts.net
   │
   ▼
Caddy
   │
   │ Docker network: caddy_proxy
   ▼
Vaultwarden
   │
   ▼
Vaultwarden application
```
 
Caddy and Vaultwarden are connected to the same dedicated Docker network:
 
```text
caddy_proxy
```
 
This allows Caddy to reach Vaultwarden using the Docker container name instead of exposing Vaultwarden directly to the host.

### Docker Network
 
The shared reverse-proxy network is:
 
```text
caddy_proxy
```
 
Inspect it with:
 
```bash
sudo docker network inspect caddy_proxy
```
 
Expected containers include:
 
```text
caddy
vaultwarden
```
 
### Caddy Configuration
 
The Caddy configuration is stored under:
 
```text
/opt/docker/caddy/conf/Caddyfile
```
 
Current configuration:
 
```caddyfile
<your-server>.tail<tailnet-id>.ts.net{
    reverse_proxy vaultwarden:80
}
```
 
Caddy terminates HTTPS for the Tailscale hostname and reverse proxies requests to Vaultwarden over the internal Docker network.

Reload the configuration after making changes:
 
```bash
cd /opt/docker/caddy
sudo docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```
 
Check the configuration:
 
```bash
sudo docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```
 
Check Caddy logs:
 
```bash
sudo docker logs caddy --tail 50
```
 
### Caddy Docker Deployment
 
Caddy is deployed using Docker Compose:
 
```text
/opt/docker/caddy/
├── compose.yaml
└── conf/
    └── Caddyfile
```
 
Caddy exposes only HTTPS:
 
```text
443/tcp
443/udp
```
 
Port 80 is not used as the public application endpoint.
 
### Important Network Design
 
Vaultwarden does not need to publish its HTTP port to the host.
 
Instead of:
 
```yaml
ports:
  - "8080:80"
```
 
Vaultwarden is connected to the internal Docker network:
 
```yaml
networks:
  - caddy_proxy
```
 
Caddy then accesses:
 
```text
vaultwarden:80
```
 
internally.
 
This reduces unnecessary host-level port exposure.
 
---
 
