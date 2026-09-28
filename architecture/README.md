## 💻 Hardware Specs

| Component | Specification |
| :--- | :--- |
| **Device** | Dell Precision M4800 |
| **OS** | Debian Linux 13 (Trixie) |
| **CPU** | Intel(R) Core(TM) i7-4810MQ (8) @ 3.80 GHz |
| **RAM** | 16 GB |
| **Primary OS Drive** | Lexar SSD NS100 512 GB (SATA) |
| **Internal Additional Storage** | Samsung SSD 860 EVO mSATA 250 GB |
| **External Storage** | OCZ Vertex 450 256 GB (USB) |
| **External Backup Drive** | Samsung PM871a 256 GB (USB) |
| **Primary Interface** | Ethernet (`eno1`) |

---

## 🐧 Operating System

- **Distribution:** Debian GNU/Linux 13 (Trixie)
- **Architecture:** x86_64
- **Boot Mode:** UEFI
- **Filesystem:** ext4
- **Encryption:** LUKS / dm-crypt

The primary system SSD is fully encrypted using LUKS. The EFI and `/boot` partitions remain unencrypted so the system can boot and then prompt for the LUKS passphrase.

---

