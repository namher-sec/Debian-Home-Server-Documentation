# Dell Precision M4800 Fan Control

Custom fan controller for the Dell Precision M4800 running Debian.

## Architecture

- `dell-bios-fan-control` disables Dell BIOS automatic fan control.
- `m4800-fan-control` monitors CPU/GPU temperatures.
- `i8kctl` controls the Dell fan states.
- systemd starts both services automatically at boot.
- BIOS fan control is restored when the BIOS-control service stops.

## Fan Curve

| Temperature | Fan |
|---|---|
| < 50°C | OFF |
| 50–69°C | LOW |
| >= 70°C | HIGH |

Hysteresis:

- HIGH → LOW below 60°C
- LOW → OFF below 47°C

## Installation

Copy the scripts:

```bash
sudo cp m4800-fan-control /usr/local/bin/
sudo cp dell-bios-fan-control /usr/local/bin/
sudo chmod +x /usr/local/bin/m4800-fan-control
sudo chmod +x /usr/local/bin/dell-bios-fan-control
