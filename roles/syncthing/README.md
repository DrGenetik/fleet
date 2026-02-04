# Syncthing Role

Automatically install and configure Syncthing for continuous file synchronization across devices.

## Overview

This role installs Syncthing daemon and GUI components on laptops and workstations. Syncthing provides decentralized, encrypted file synchronization without requiring a central server.

## Supported Platforms

- **Linux**: Debian/Ubuntu (apt) - installs syncthing + syncthingtray
- **macOS**: Darwin (homebrew) - installs syncthing only

## Features

- **Decentralized sync**: Direct device-to-device synchronization
- **End-to-end encryption**: Files encrypted in transit
- **User-level service**: Runs as user systemd/launchd service
- **GUI included**: Syncthingtray (Linux) for system tray integration
- **No cloud storage**: Files stay on your devices

## Requirements

### Dependencies

- **Base role**: Ensures package managers configured
- **User core role**: Creates user account (uses `user_name` variable)

### External

- Syncthing runs on ports 22000 (TCP/UDP) and 8384 (web GUI)
- Devices must be paired manually via web interface
- Folder shares configured manually per device

## Variables

### Required Variables

None. Role uses `user_name` from `group_vars/all/vars.yml`.

### Default Variables

This role has no configurable defaults. All configuration happens through Syncthing's web UI after installation.

### Platform-Specific Variables

**Linux** (`vars/debian.yml`):

```yaml
syncthing_package_names:
  - syncthing
  - syncthingtray
```

**macOS** (`vars/darwin.yml`):

```yaml
syncthing_package_names:
  - syncthing
```

## Usage

### Adding to Hosts

Add `syncthing` to the `roles_to_run` list in host configuration:

```yaml
# host_vars/rincewind.yml
roles_to_run:
  - base
  - user_core
  - syncthing  # Add this
```

### Initial Configuration

After applying the role:

1. **Access web UI**:

   ```bash
   # Linux/macOS - UI opens automatically or visit:
   http://localhost:8384
   ```

2. **Add remote devices**:
   - Settings → Show ID → Copy device ID
   - On other device: Actions → Add Remote Device → Paste ID

3. **Share folders**:
   - Add Folder → Choose directory
   - Sharing → Select devices to sync with

4. **Configure sync options**:
   - File versioning (keep deleted files)
   - Ignore patterns (.git, node_modules, etc.)
   - Scan intervals

### Accessing Service

**Linux**:

```bash
# Check status
systemctl --user status syncthing.service

# View logs
journalctl --user -u syncthing.service -f

# Restart service
systemctl --user restart syncthing.service
```

**macOS**:

```bash
# Check status
launchctl list | grep syncthing

# View logs
tail -f ~/Library/Logs/Syncthing/*.log

# Restart service
launchctl kickstart -k gui/$(id -u)/homebrew.mxcl.syncthing
```

## Installed Components

### Linux (Debian/Ubuntu)

**Packages:**

- `syncthing`: Core synchronization daemon
- `syncthingtray`: Qt-based system tray application

**Services:**

- `syncthing.service`: User systemd service (enabled & started)
- Runs as user (not root) via `systemctl --user`

**Files Created:**

- `~/.config/syncthing/`: Configuration and database
- `~/.local/state/syncthing/`: Logs and state

### macOS (Darwin)

**Packages:**

- `syncthing`: Core synchronization daemon (no GUI package available)

**Services:**

- `homebrew.mxcl.syncthing`: User launchd service (enabled & started)

**Files Created:**

- `~/Library/Application Support/Syncthing/`: Configuration and database
- `~/Library/Logs/Syncthing/`: Logs

## Service Architecture

### User Service vs System Service

This role configures **user-level** services:

- Runs as your user (not root)
- Starts when you log in
- Accesses your files with your permissions
- No sudo needed for configuration

**Comparison to nas_mount role:**

- `nas_mount`: System-level (root), mounts for all users
- `syncthing`: User-level, one instance per user

### Why User Service?

1. **Security**: No root access needed to sync files
2. **Isolation**: Each user has independent Syncthing instance
3. **Permissions**: Natural access to user's home directory
4. **Standard pattern**: Syncthing designed for user-level operation

## Default Folder Locations

Syncthing creates a default "Sync" folder on first run:

- **Linux**: `~/Sync/`
- **macOS**: `~/Sync/`

Additional folders can be added through the web UI.

## Port Usage

**Default ports:**

- `8384`: Web GUI (localhost only by default)
- `22000`: TCP sync protocol
- `22000`: UDP discovery and NAT traversal
- `21027`: UDP local discovery broadcasts

**Firewall notes:**

- Web GUI binds to 127.0.0.1 (no firewall rules needed)
- Sync ports use UPnP for automatic port forwarding
- Manual firewall rules only needed if UPnP disabled

## Troubleshooting

### Service Not Running

**Linux**:

```bash
# Check service status
systemctl --user status syncthing.service

# Check if enabled
systemctl --user is-enabled syncthing.service

# Start manually
systemctl --user start syncthing.service
```

**macOS**:

```bash
# Check if loaded
launchctl list | grep syncthing

# Load service manually
launchctl load ~/Library/LaunchAgents/homebrew.mxcl.syncthing.plist
```

### Cannot Connect to Web UI

```bash
# Verify service listening
ss -tlnp | grep 8384      # Linux
lsof -i :8384             # macOS

# Check Syncthing logs for errors
journalctl --user -u syncthing.service -n 50  # Linux
cat ~/Library/Logs/Syncthing/syncthing.log    # macOS

# Verify not bound to external interface
# Should show 127.0.0.1:8384, not 0.0.0.0:8384
```

### Devices Not Connecting

```bash
# Check Syncthing is reachable
# Visit web UI → Actions → Show ID
# Verify device ID matches on both sides

# Check for port blocks
# Ensure 22000 TCP/UDP not blocked by firewall

# Check relay status (fallback if direct connection fails)
# Web UI → Actions → Advanced → Relay Status
```

### Sync Conflicts

Syncthing creates `.sync-conflict` files when conflicts occur:

```bash
# Find conflict files
find ~/Sync -name "*.sync-conflict-*"

# Conflicts occur when:
# - Same file edited on multiple devices while offline
# - File modified before previous sync completed

# Resolution:
# 1. Review conflict files manually
# 2. Merge changes or choose one version
# 3. Delete unwanted conflict files
```

## Security Considerations

### Default Security

Syncthing is secure by default:

- **TLS encryption**: All connections encrypted
- **Device authentication**: Must manually approve each device
- **Local web UI**: Only accessible from localhost
- **No default shares**: Must explicitly share folders

### Remote Access

To access web UI remotely (not recommended):

1. **Use SSH tunnel instead** (secure):

   ```bash
   ssh -L 8384:localhost:8384 remote-host
   # Then visit http://localhost:8384
   ```

2. Or configure Syncthing to bind to network interface (less secure)

## Performance Tuning

### Resource Usage

Syncthing monitors ~10-20 MB RAM per 10,000 files. For large shares:

```bash
# Check memory usage
ps aux | grep syncthing

# Adjust scan intervals in web UI
# Settings → Folder → Advanced → Scan Interval
# Increase for large folders (e.g., 3600s = 1 hour)
```

### Network Bandwidth

```bash
# Limit bandwidth in web UI
# Settings → Connections → Rate Limits
# Set upload/download limits if needed
```

## Implementation Details

### Check Mode Compatibility

The role handles Ansible check mode correctly:

- **Linux**: User systemd service skipped in check mode (fleet-4g6.1 fix)
- **macOS**: Launchd operations work in check mode
- Package installation: Always runs (idempotent)

### Platform Detection

Role uses standard Ansible facts:

- `{{ ansible_facts.system }}` → "Linux" or "Darwin"
- Includes platform-specific task files automatically
- Variables loaded from `vars/debian.yml` or `vars/darwin.yml`

## Testing

### Role Test

```bash
# Dry run (check mode)
ansible-playbook roles/syncthing/tests/test.yml --check --diff

# Apply locally
ansible-playbook roles/syncthing/tests/test.yml --ask-become-pass
```

### Integration Test

```bash
# Apply to specific host
ansible-playbook local.yml -l rincewind --ask-become-pass

# Verify service running
ssh rincewind 'systemctl --user status syncthing.service'

# Verify web UI accessible
ssh rincewind 'curl -s http://localhost:8384 | grep -i syncthing'
```

## Common Use Cases

### Syncing Documents

```yaml
# Share ~/Documents between laptop and workstation
# 1. On laptop: Add folder ~/Documents
# 2. Share with workstation device ID
# 3. On workstation: Accept folder share
# 4. Files sync continuously
```

### Code Projects

```yaml
# Sync development projects with .stignore rules
# Create ~/Code/.stignore:
# .git
# node_modules
# __pycache__
# *.pyc
# .venv
```

### Photo Backup

```yaml
# One-way sync from laptop to workstation
# 1. Add ~/Pictures on laptop
# 2. Set folder type to "Send Only"
# 3. Accept on workstation as "Receive Only"
# 4. Photos backed up automatically
```

## Architecture Decisions

### Why User Service?

- Syncthing designed for user-level operation
- No need for root privileges
- Natural home directory access
- Standard across Linux and macOS

### Why No Auto-Configuration?

- Device IDs are unique per installation
- Folder shares are user-specific preferences
- Manual pairing ensures security
- Web UI provides intuitive configuration

### GUI Choice

- **Linux**: `syncthingtray` provides Qt system tray (well-maintained)
- **macOS**: No mature GUI package in homebrew (web UI sufficient)

## References

- **Official docs**: <https://docs.syncthing.net/>
- **fleet-4g6**: Epic for syncthing role creation
- **fleet-4g6.1**: Check mode compatibility fix

## Author

T.R. Fullhart (2026)
