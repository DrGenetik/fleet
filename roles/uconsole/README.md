# uConsole Role

Role for managing configurations specific to uConsole and similar small form factor gaming devices. This role handles hardware-specific settings that go beyond the generic UMPC role.

## Features

- **Audio Configuration**: PCM5102 DAC and USB audio device setup
- **Hardware Button Mapping**: GPIO button configuration for game controls and navigation
- **Backlight Control**: Screen brightness control with proper permissions

## Requirements

- Debian/Raspbian operating system
- uConsole or compatible small form factor device

## Usage

Add the `uconsole` role to a device's `roles_to_run` in its `host_vars` file:

```yaml
# host_vars/huginn.yml
roles_to_run:
  - umpc        # Small screen and low-performance settings
  - uconsole    # uConsole-specific hardware configuration
```

## Role Variables

| Variable | Default | Description |
| --- | --- | --- |
| `uconsole_enable_audio` | `true` | Configure audio device settings |
| `uconsole_enable_buttons` | `true` | Configure hardware button mappings |
| `uconsole_enable_backlight` | `true` | Enable backlight control permissions |

## Notes

- This role assumes a ClockworkPi uConsole running Raspbian
- Audio drivers (PCM5102 DAC) may need firmware updates on some devices
- Hardware button mappings depend on GPIO kernel driver support
- Backlight control requires `video` group membership for the user
