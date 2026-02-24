# Cellular Modem Role

Role for managing cellular modem configuration via ModemManager and NetworkManager on Linux devices.

## Features

- **ModemManager Installation**: Installs ModemManager for modem hardware detection and management
- **NetworkManager Integration**: Configures NetworkManager for cellular network management
- **APN Configuration**: Supports setting Access Point Name (APN) for cellular connections
- **1Password Integration Ready**: Can store sensitive credentials (PIN, APN) via 1Password lookups

## Requirements

- Linux operating system (Debian/Ubuntu)
- ModemManager and NetworkManager support
- Compatible USB cellular modem or integrated modem hardware

## Usage

Add the `cellular_modem` role to a device's `roles_to_run` in its `host_vars` file:

```yaml
# host_vars/huginn.yml
roles_to_run:
  - umpc
  - uconsole
  - cellular_modem
```

## Role Variables

| Variable | Default | Description |
| --- | --- | --- |
| `cellular_modem_enable_modem_manager` | `true` | Install and enable ModemManager |
| `cellular_modem_enable_network_manager` | `true` | Install and enable NetworkManager |
| `cellular_modem_apn_configured` | `false` | Enable APN configuration |
| `cellular_modem_apn` | undefined | APN string for cellular connection |
| `cellular_modem_connection_name` | `Cellular` | NetworkManager connection name |

## 1Password Integration

For sensitive credentials like PIN or APN, use 1Password lookups in host_vars:

```yaml
# host_vars/huginn.yml
cellular_modem_apn: "{{ lookup('community.general.onepassword', 'item_id', vault='VaultName', field='apn') }}"
cellular_modem_pin: "{{ lookup('community.general.onepassword', 'item_id', vault='VaultName', field='pin') }}"
```

## Platform Support

- **Linux (Debian/Ubuntu)**: Full support for ModemManager and NetworkManager
- **macOS (Darwin)**: Limited support; most USB cellular modems require special drivers

## Notes

- ModemManager must be running for modem detection
- NetworkManager handles the actual network connection and APN configuration
- PIN management may require additional manual setup depending on modem
- Some carriers restrict certain connection types; consult your carrier documentation
