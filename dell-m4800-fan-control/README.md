# Dell Precision M4800 Fan Control

Custom fan controller for the Dell Precision M4800 running Debian.

## Architecture

- `dell-bios-fan-control` disables Dell BIOS automatic fan control.
- `m4800-fan-control` monitors CPU and GPU temperatures.
- `i8kctl` provides high-speed fan control.
- `dell_smm` hwmon PWM provides the quiet normal operating speed.
- systemd starts both services automatically at boot.
- BIOS fan control is restored when the BIOS-control service stops.

## Fan Curve

| Temperature | Fan |
|---|---|
| < 70°C | Quiet — PWM 75 (~2500 RPM) |
| ≥ 70°C | HIGH (~4900 RPM) |

### Hysteresis

- HIGH → QUIET below **60°C**
- QUIET → HIGH at **70°C**

This prevents rapid switching between fan speeds.

## Quiet Mode

Testing on this M4800 showed that PWM values do not provide linear fan-speed control:

| PWM | Result |
|---:|---|
| 60 | Fans OFF |
| 75 | ~2500 RPM, quieter |
| 80 | ~2500 RPM, more noticeable |
| 128 | ~2500 RPM |
| 255 | No useful increase |

Therefore, **PWM 75** is used for normal operation.

## High-Speed Mode

For higher temperatures, the controller uses:

```bash
i8kctl fan 2 2
```

This produces approximately 4900 RPM on this M4800.

`i8kctl` readback is unreliable on this system. For example, `i8kctl fan 2 2` may report `1 1` even though the fans are actually running at maximum speed. The controller therefore does not use `i8kctl` output as feedback.

## Safety

The controller fails toward higher cooling:

- Sensor failure → HIGH
- Invalid temperature → HIGH
- Fan-control failure → HIGH
- Controller shutdown → HIGH
- BIOS automatic fan control must be disabled first

The hottest CPU/GPU temperature is used for fan decisions.

## Installation

Copy the scripts:

```bash
sudo cp m4800-fan-control /usr/local/bin/
sudo cp dell-bios-fan-control /usr/local/bin/

sudo chmod +x /usr/local/bin/m4800-fan-control
sudo chmod +x /usr/local/bin/dell-bios-fan-control
```

Copy the systemd services:

```bash
sudo cp systemd/dell-bios-fan-control.service /etc/systemd/system/
sudo cp systemd/m4800-fan-control.service /etc/systemd/system/
```

Reload and enable:

```bash
sudo systemctl daemon-reload

sudo systemctl enable dell-bios-fan-control.service
sudo systemctl enable m4800-fan-control.service
```

Start the services:

```bash
sudo systemctl start dell-bios-fan-control.service
sudo systemctl start m4800-fan-control.service
```

## Check Status

```bash
systemctl status dell-bios-fan-control.service
systemctl status m4800-fan-control.service
```

View controller logs:

```bash
journalctl -u m4800-fan-control.service -f
```

## Testing

Generate CPU load with:

```bash
stress-ng --cpu 4 --timeout 180s
```

- Under normal usage, the fans remain at the quiet PWM 75 setting.
- At approximately 70°C, the controller switches to HIGH speed.
- After the load is removed, it returns to PWM 75 once the temperature falls below 60°C.
