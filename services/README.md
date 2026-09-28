## 🚀 Currently Running Services
 
All services are containerized using Docker and Docker Compose, managed behind a strict UFW firewall.
 
| Service | Category | Deployment | Port | Description |
|---|---|---|---:|---|
| Tailscale | Networking | Native Service | — | Encrypted mesh VPN for secure remote access without open ports |
| Caddy | Reverse Proxy / HTTPS | Docker | `443` | Reverse proxy providing HTTPS access to Vaultwarden |
| Vaultwarden | Password Manager | Docker | Internal `80` | Self-hosted Bitwarden-compatible password manager |
| AdGuard Home | Network / Security | Docker | — | Network-wide DNS ad-blocking and tracking sinkhole |
| Nextcloud | Cloud & Storage | Docker | `8085` | Self-hosted personal cloud storage, file sync, and backup |
| Beszel | Telemetry / Stats | Docker | `8090` | Lightweight server resource monitoring for CPU, RAM, GPU, temperatures, and Docker |
| Portainer | Management | Docker | `9443` | Web-based management UI for Docker containers, images, volumes, and stacks |
| Stirling PDF | Productivity | Docker | `8080` | Self-hosted web-based PDF toolkit for conversion, editing, merging, splitting, OCR, and other PDF operations |
| Uptime Kuma | Monitoring | Docker | `3001` | Self-hosted uptime and service monitoring |
| ntfy | Notifications | Docker | `8095` | Self-hosted push notification service for monitoring alerts |
| Homepage | Dashboard | Docker | `3000` | Central dashboard for launching all web apps |
| Joplin Server | Note taking | Docker | `22300` | Self-hosted notes and to-do application |
| Paperless-ngx | Document Management | Docker | `8000` | Open-source document management and archiving system |
 
---
 
## 🔮 Planned Services
 
- [ ] RSS reader — self-hosted RSS feed aggregation
---


