## 🐳 Docker
 
Docker Compose is used for every service (not standalone `docker run`) so configuration is reproducible and portable to another machine/distro.
 
### Reverse Proxy Network
 
A dedicated external Docker network is used for services that need to communicate with Caddy:
 
```text
caddy_proxy
```
 
Create it if it does not already exist:
 
```bash
sudo docker network create caddy_proxy
```
 
Services that should be accessible through Caddy can then join this network.
 
For example:
 
```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
 
    networks:
      - caddy_proxy
 
networks:
  caddy_proxy:
    external: true
```
 
Caddy can then reach the service by its Docker container name:
 
```text
vaultwarden:80
```
 
Only services intended to be reverse-proxied should be connected to `caddy_proxy`.
 
### 📂 Docker Directory Structure
 
Docker Compose services are organized into separate directories under `/opt/docker/`.
 
```text
/opt/docker/
├── adguard/
├── beszel/
├── caddy/
│   ├── compose.yaml
│   └── conf/
│       └── Caddyfile
├── firefly-iii/
├── nextcloud/
├── portainer/
├── stirling-pdf/
└── vaultwarden/
```
 
Caddy and Vaultwarden are separate Compose projects but communicate through the shared external Docker network:
 
```text
caddy_proxy
```
 
---
