# UMPC Role

Role for managing configurations specific to Ultra Mobile PCs (UMPCs) like the ClockworkPi uConsole and GPD MicroPC. These devices are characterized by small screens and low performance.

## Features

- **Display Scaling**: Sets environment variables (`GDK_SCALE`, `QT_SCALE_FACTOR`, etc.) to make the GUI readable on small screens.
- **Accessibility**: Configures TTY font sizes for better visibility in terminal.

## Requirements

- Linux operating system (Debian/Ubuntu/Raspbian)

## Usage Warnings

**Important:** These devices have limited processing power and memory. You **must omit** heavy applications from their `host_vars`.

When configuring a UMPC, do **not** add the following roles to the `roles_to_run` list:

- `printing_3d`
- `CAD` (if applicable)
- `gaming` (if applicable)
- `Blender` (if applicable)

## Role Variables

| Variable | Default | Description |
| --- | --- | --- |
| `umpc_gui_scaling` | `"1.25"` | Multiplier for GUI scaling |
| `umpc_cursor_size` | `"32"` | Size of the X cursor |
| `umpc_tty_font` | `"Terminus"` | Font face for TTY |
| `umpc_tty_fontsize` | `"10x20"` | Font size for TTY |
