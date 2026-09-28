## 🔐 Vaultwarden
 
Vaultwarden is the self-hosted password manager used on the server.
 
It is compatible with Bitwarden clients and stores the user's password vault on the home server.
 
### Access
 
Vaultwarden is accessed through the Caddy HTTPS reverse proxy:
 
```text
<your-server>.tail<tailnet-id>.ts.net
```
 
Access requires connectivity to the Tailscale network.
 
There is no router port forwarding for Vaultwarden.
 
```text
Internet
   │
   X
   │
   │ No direct inbound port forwarding
   │
Tailscale
   │
   ▼
Debian Home Server
   │
   ▼
Caddy :443
   │
   ▼
Vaultwarden :80
```
 
### Registration
 
Initial account registration was enabled during setup.
 
After the account was created and the existing Bitwarden vault was imported, new user registration was disabled.
 
This prevents unknown users from creating accounts on the Vaultwarden instance.
 
### Password Vault
 
The existing Bitwarden password vault was imported into Vaultwarden.
 
Vaultwarden should be treated as sensitive infrastructure.
 
The following should never be committed to Git:
 
- Vaultwarden database
- Vaultwarden attachments
- User passwords
- Vaultwarden environment secrets
- Admin tokens
- Encryption keys
- Backup files containing vault data
### Admin Panel
 
The Vaultwarden admin interface is disabled unless explicitly required.
 
This reduces the exposed attack surface.
 
If the admin interface is enabled temporarily for maintenance, it should be disabled again afterward.
 
### Security
 
The Vaultwarden deployment follows these principles:
 
- HTTPS through Caddy
- Tailscale-only remote access
- No router port forwarding
- Vaultwarden not directly published to the host
- Dedicated Docker reverse-proxy network
- Registration disabled after initial account creation
- Strong master password
- Argon2id used for password hashing where supported/configured
- Secrets kept outside Git
- Regular backups of Vaultwarden data
- Caddy handles HTTPS
- Vaultwarden is not directly exposed on a host port
### Backup Considerations
 
Vaultwarden data must be included in the server backup strategy.
 
The backup should include the persistent Vaultwarden application data/database.
 
Because the vault contains highly sensitive information, backups must remain encrypted and must never be uploaded to a public repository.
 
---
