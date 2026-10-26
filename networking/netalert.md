## NetAlertX

[NetAlertX](https://github.com/netalertx/NetAlertX) is a self-hosted network monitoring and device discovery tool that maintains an inventory of devices connected to your network. It helps identify unknown devices, track device presence, and monitor changes in your home network.

### Features

- **Device discovery:** Discover devices connected to the local network.
- **Network visibility:** View device information, including IP addresses, MAC addresses, and hostnames when available.
- **Device tracking:** Monitor device presence and changes over time.
- **Security awareness:** Identify unfamiliar devices that may require further investigation.
- **Notifications:** Configure alerts for device changes using supported notification integrations.
- **Self-hosted:** Keep network inventory and monitoring under your own control.

### Access

Open the NetAlertX web interface using your Debian home server's IP address and its configured web UI port:

`http://<server-ip>:20211`

Replace `<server-ip>` with your server's IP address. This example assumes the default NetAlertX web UI port and should be adjusted if your deployment uses a different port or access method.

### Notes

- NetAlertX is intended for discovering and monitoring devices on your network; it is not a replacement for a firewall or intrusion detection system.
- Device discovery accuracy depends on the configured scanning methods and network setup.
- Keep NetAlertX updated and restrict access to its web interface to trusted devices.
- Back up its persistent configuration and database data so the device inventory can be recovered if needed.

### Resources

- [NetAlertX GitHub Repository](https://github.com/netalertx/NetAlertX)
- [Official Documentation](https://docs.netalertx.com/)
- [Docker Compose Documentation](https://github.com/netalertx/NetAlertX/blob/main/docs/DOCKER_COMPOSE.md)
