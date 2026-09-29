# 🏡 Home Server Repository

![Debian](https://img.shields.io/badge/OS-Debian-A81D33?style=flat&logo=debian&logoColor=white)
![Android](https://img.shields.io/badge/Mobile-Android-34A853?style=flat&logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Kernel-Linux-FCC624?style=flat&logo=linux&logoColor=black)
![Docker](https://img.shields.io/badge/Container-Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Tailscale](https://img.shields.io/badge/Mesh-Tailscale-242424?style=flat&logo=tailscale&logoColor=white)

![AdGuard Home](https://img.shields.io/badge/DNS-AdGuard%20Home-68BC71?style=flat&logo=adguard&logoColor=white)
![Caddy](https://img.shields.io/badge/Proxy-Caddy-1F88C0?style=flat&logo=caddy&logoColor=white)
![Vaultwarden](https://img.shields.io/badge/Password%20Manager-Vaultwarden-175DDC?style=flat&logo=bitwarden&logoColor=white)
![Nextcloud](https://img.shields.io/badge/Cloud-Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)
![Portainer](https://img.shields.io/badge/Manage-Portainer-13BEF9?style=flat&logo=portainer&logoColor=white)
![Uptime Kuma](https://img.shields.io/badge/Monitoring-Uptime%20Kuma-5CDD8B?style=flat&logo=uptimekuma&logoColor=white)
![ntfy](https://img.shields.io/badge/Notifications-ntfy-317F6B?style=flat&logo=ntfy&logoColor=white)
![Beszel](https://img.shields.io/badge/Stats-Beszel-10B981?style=flat&logo=beszel&logoColor=white)
![Stirling PDF](https://img.shields.io/badge/PDF-Stirling%20PDF-FF6B35?style=flat&logo=adobeacrobatreader&logoColor=white)

Documentation for my personal home server and self-hosted homelab running on Debian Linux.

This repository documents the server's **architecture, storage, networking, Docker environment, self-hosted services, backups, hardware-specific configuration, and recovery procedures**.

> **Security + simplicity + reliability, with minimal ongoing maintenance.**

---

## 📚 Documentation

| Section | Description |
|---|---|
| 🏗️ [Architecture](architecture/) | Hardware, operating system, and overall server architecture |
| 💾 [Storage](storage/) | Disk layout, filesystems, encryption, mounts, and storage expansion |
| 🌐 [Networking](networking/) | Network configuration, Tailscale, Caddy, HTTPS, and DNS |
| 🐳 [Docker](docker/) | Docker, Compose structure, networking, storage, and configuration practices |
| ⚙️ [Services](services/) | Self-hosted services and their current configuration |
| ⚙️ [Security and Optimizations](security-and-optimizations/) | Security and Optimizations performed on the server |
| 💾 [Backup](backup/) | Automated backups, systemd configuration, and restore procedures |
| 🌡️ [Fan Control](fan-control/) | Dell M4800 fan control and related systemd services |
| ☁️ [Nextcloud Preview](nextcloud-preview/) | Automated Nextcloud preview generation |
| 🔧 [Troubleshooting](troubleshooting/) | Common problems, diagnostics, and useful commands |
| 🔄 [Rebuild](rebuild/) | Complete server rebuild and recovery procedure |

---

## 🧱 Design Philosophy

The server is designed around a few simple principles:

- **Keep the infrastructure simple**
- **Minimize unnecessary dependencies**
- **Use Docker Compose for self-hosted services**
- **Keep services independently manageable**
- **Encrypt storage at rest**
- **Use Tailscale for remote access**
- **Keep sensitive data and secrets out of Git**
- **Document configuration and recovery procedures**

The storage architecture intentionally avoids **RAID, LVM, ZFS, and storage pooling**. Each SSD is encrypted and mounted independently, allowing individual drives to be replaced, disconnected, or upgraded without rebuilding the entire storage system.

---

## 🗂️ Repository Structure

Each independently managed component has its own directory and `README.md`.

The README inside each directory contains the documentation required for that component, including configuration, installation, usage, and recovery information where applicable.

```text
Debian-Home-Server-Documentation/
│
├── README.md
├── LICENSE
│
├── architecture/
│   └── README.md
├── storage/
│   └── README.md
├── networking/
│   └── README.md
├── docker/
│   └── README.md
├── services/
│   └── README.md
├── security-and-optimizations/
│   └── README.md
├── backup/
│   ├── README.md
│   ├── home-server-backup.sh
│   └── home-server-backup.service
├── fan-control/
│   ├── README.md
│   ├── dell-bios-fan-control.service
│   └── m4800-fan-control.service
├── nextcloud-preview/
│   ├── README.md
│   ├── nextcloud-preview.service
│   └── nextcloud-preview.timer
├── troubleshooting/
│   └── README.md
└── rebuild/
    └── README.md
```

---

## 📜 License

This repository contains personal documentation and configuration examples for my home server. Unless otherwise specified, the documentation is licensed under the MIT License. See `LICENSE` for details.
