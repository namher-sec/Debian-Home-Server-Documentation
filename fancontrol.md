# Dell Precision M4800 Fan Control

## Overview

Configured custom fan control on a Dell Precision M4800 running Debian 13.

The goal was to stop the fans from constantly running at low speed during normal idle temperatures while still providing automatic cooling under load.

## Components

- `dell_smm_hwmon` — exposes Dell temperature and fan information.
- `i8kctl` — controls the Dell fan states.
- `dell-bios-fan-control` — disables BIOS automatic fan control so userspace can control the fans.
- `m4800-fan-control` — custom temperature-based fan controller.
- `systemd` — starts the fan-control services automatically at boot.

## Fan States

```text
0 = OFF
1 = LOW
2 = HIGH
```

## Fan Curve

The controller uses the highest temperature between the CPU and GPU sensors.

| Temperature | Fan state |
|------------|-----------|
| < 50°C | OFF |
| 50–69°C | LOW |
| ≥ 70°C | HIGH |

Hysteresis is used to prevent unnecessary fan switching:

```text
HIGH → LOW  below 60°C
LOW  → OFF  below 47°C
```

This keeps the fans off during normal idle temperatures around 43–46°C.

## BIOS Fan Control

The Dell BIOS was found to override manual `i8kctl` commands unless BIOS fan control was disabled first.

The `dell-bios-fan-control` utility is therefore run before the custom controller:

```bash
sudo dell-bios-fan-control 0
```

This gives fan control to the userspace controller.

BIOS control is restored when the corresponding systemd service stops:

```bash
sudo dell-bios-fan-control 1
```

## Custom Controller

The script is installed at:

```text
/usr/local/bin/m4800-fan-control
```

It:

- Detects the `dell_smm` and `coretemp` hwmon devices dynamically.
- Reads CPU temperatures from `coretemp`.
- Reads the GPU temperature from the Dell SMM sensor.
- Uses the highest CPU/GPU temperature.
- Controls both fans using `i8kctl`.
- Polls temperatures every 3 seconds.
- Uses hysteresis to avoid rapid fan switching.
- Sets both fans to HIGH when temperature readings fail.
- Sets both fans to HIGH if fan control commands repeatedly fail.
- Sets both fans to HIGH when the controller is stopped.

## systemd

Two services are used:

```text
dell-bios-fan-control.service
m4800-fan-control.service
```

The fan controller depends on the BIOS-control service and starts after BIOS fan control has been disabled.

`i8kmon.service` is disabled to prevent another fan-control daemon from competing with the custom controller.

Check the services:

```bash
systemctl status dell-bios-fan-control.service
systemctl status m4800-fan-control.service
```

View controller logs:

```bash
journalctl -u m4800-fan-control.service -f
```

Check temperatures and fan RPM:

```bash
sensors
```

## Result

Normal idle temperatures around 43–46°C now keep both fans OFF.

During higher CPU/GPU temperatures, the fans automatically switch to LOW and then HIGH when required.

The setup is persistent across reboots through systemd.
