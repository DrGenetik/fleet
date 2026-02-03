# NAS Mount Role

Automatically mount Synology NAS Public volume using autofs (on-demand mounting).

## Overview

This role configures automatic mounting of network file shares via autofs. Mounts appear on-demand when accessed and auto-unmount after a timeout period. Designed for ZeroTier VPN environments with network interruption tolerance.

## Supported Platforms

- **Linux**: Debian/Ubuntu (apt), Arch Linux (pacman)
- **macOS**: Darwin (built-in NFS/autofs)

## Features

- **On-demand mounting**: Shares mount automatically when accessed
- **Auto-unmount**: Unmounts after idle timeout (default 5 minutes)
- **Network resilience**: `hard,intr` mount options tolerate ZeroTier interruptions
- **No credentials**: NFS authentication via UID/GID mapping (no passwords)
- **ZeroTier integration**: Uses hostnames from fleet-6o5 peer discovery

## Requirements

### Dependencies

- **ZeroTier role** (fleet-6o5): Provides NAS hostname resolution via `/etc/hosts`
- **Base role**: Ensures system package managers configured

### External

- Synology NAS with NFS exports configured
- ZeroTier subnet (198.51.100.0/24) allowed in NFS export permissions
- Network connectivity via ZeroTier VPN

## Variables

### Required Variables

None. All variables have sensible defaults.

### Default Variables

See `defaults/main.yml` for complete list:

```yaml
# NAS connection
nas_hostname: "nas-server.example_network.zt"
nas_share_path: "/volume1/Public"
nas_mount_point: "/media/synology/public"

# Protocol
nas_protocol: "nfs"
nas_nfs_version: "4.1"

# Mount options
nas_nfs_options: "rw,hard,intr,nosuid,timeo=600,retrans=2,_netdev"

# Autofs behavior
nas_autofs_timeout: 300  # seconds (5 minutes)
```

### Platform-Specific Variables

**Linux** (`vars/debian.yml`):

```yaml
nas_mount_packages:
  - nfs-common
  - autofs
```

**macOS** (`vars/darwin.yml`):

```yaml
nas_mount_packages: []  # Built-in NFS support
```

## Usage

### Adding to Hosts

Add `nas_mount` to the `roles_to_run` list in host configuration:

```yaml
# host_vars/rincewind.yml
roles_to_run:
  - base
  - user_core
  - nas_mount  # Add this
```

### Overriding Variables

Override defaults in `host_vars/<hostname>.yml` if needed:

```yaml
# Custom mount point
nas_mount_point: "/mnt/nas/public"

# Shorter timeout (2 minutes)
nas_autofs_timeout: 120

# Different share
nas_share_path: "/volume1/Documents"
```

### Testing Mount

After applying the role:

```bash
# Trigger auto-mount by accessing path
ls /media/synology/public

# Verify mount appeared
mount | grep synology

# Check autofs status
systemctl status autofs  # Linux
automount -v              # macOS

# Test file access
touch /media/synology/public/test.txt

# Wait for auto-unmount (default 5 min)
# Mount disappears when idle
```

## Installed Components

### Linux (Debian/Ubuntu)

**Packages:**

- `nfs-common`: NFS client tools (showmount, mount.nfs, rpcbind)
- `autofs`: Automounter daemon

**Services:**

- `autofs.service`: Autofs daemon (enabled & started)
- `rpcbind.service`: RPC service for NFS (dependency of nfs-common)

**Files Created:**

- `/etc/auto.master.d/synology.autofs`: Master map entry
- `/etc/auto.synology`: Map file with mount definition

### macOS (Darwin)

**Packages:** None (uses built-in NFS)

**Services:**

- `automount`: Built-in macOS automounter (refreshed via `automount -vc`)

**Files Created:**

- `/etc/auto_synology`: Map file with mount definition
- `/etc/auto_master`: Updated with map reference

## Mount Options Explained

Default NFS options: `rw,hard,intr,nosuid,timeo=600,retrans=2,_netdev`

- `rw`: Read-write access
- `hard`: Retry indefinitely if NAS unreachable (data integrity priority)
- `intr`: Allow Ctrl+C to interrupt hung operations (prevents system freeze)
- `nosuid`: Security - ignore setuid/setgid bits on NFS files
- `timeo=600`: 60 second timeout (600 deciseconds) before retry
- `retrans=2`: 2 retransmissions before reporting error
- `_netdev`: Wait for network before mounting (critical for ZeroTier)
- `nfsvers=4.1`: Use NFSv4.1 protocol (added automatically)

## Network Interruption Behavior

**During ZeroTier disconnect:**

- Autofs keeps mount point available
- File operations hang (due to `hard` mount)
- User can press Ctrl+C to interrupt (due to `intr` flag)
- No data loss or corruption

**After ZeroTier reconnect:**

- Operations automatically resume
- No manual intervention needed
- Files remain accessible

## Troubleshooting

### Mount Not Appearing

```bash
# Check autofs is running
systemctl status autofs  # Linux
automount -v              # macOS

# Check autofs logs
journalctl -u autofs -n 50  # Linux
log show --predicate 'process == "automount"' --last 5m  # macOS

# Verify ZeroTier hostname resolves
ping nas-server.example_network.zt

# Check NFS exports visible
showmount -e nas-server.example_network.zt
```

### Access Denied Errors

```bash
# Verify IP in NFS export permissions
showmount -e nas-server.example_network.zt

# Check ZeroTier IP
ip -4 addr show ztc6mxkhrf  # Linux
ifconfig ztc6mxkhrf          # macOS

# Ensure IP in 198.51.100.0/24 subnet
# Synology must allow this subnet in NFS rules
```

### Permission Errors

NFS uses UID/GID mapping:

- Files owned by UID 1026 on NAS appear as UID 1026 locally
- Ensure your local user has matching UID or read/write permissions
- Check with: `ls -ln /media/synology/public`

### Mount Hangs

```bash
# Check ZeroTier connection
zerotier-cli listpeers | grep synology

# Try Ctrl+C to interrupt (intr option)
# Restart autofs if necessary
sudo systemctl restart autofs  # Linux
sudo automount -vc              # macOS
```

## Implementation Details

### User Service vs System Service

This role configures **system-level** autofs:

- Runs as root
- Mounts accessible to all users
- Starts at boot (after network/ZeroTier)

Unlike `syncthing` role which uses user-level systemd services, NAS mounts require root privileges for mount operations.

### Dependencies

**Service dependencies** (handled automatically):

- Linux: autofs waits for `network-online.target`
- ZeroTier: `_netdev` mount option ensures network ready
- NFS: `rpcbind.service` started by nfs-common package

**Role dependencies:**

- Must run after `base` role (package managers configured)
- Should run after ZeroTier role (hostname resolution)

### File Ownership

**Created by role:**

- Mount point directory: Owned by `nas_mount_user` (default: kayos)
- Autofs config files: Owned by root (required)

**Mounted files:**

- Ownership determined by NAS (UID/GID mapping)
- Permissions preserved from NAS filesystem

## Architecture Decisions

### Why NFS over SMB?

1. **No credentials needed**: NFS uses UID/GID, no password management
2. **Simpler configuration**: No credentials file per host
3. **Better Linux integration**: Native POSIX semantics
4. **Proven working**: Minecraft server uses same pattern
5. **Lower overhead**: Less protocol complexity

See fleet-422.1 research for detailed comparison.

### Why Autofs over /etc/fstab?

1. **On-demand mounting**: Only mounts when accessed, saves resources
2. **No boot delays**: System boots even if NAS/ZeroTier unavailable
3. **Auto-unmount**: Cleans up idle mounts automatically
4. **Graceful degradation**: Mount failures don't block system

### Why Hard Mounts?

- **Data integrity**: Ensures writes complete (retries until success)
- **Consistency**: Prevents silent data loss on network issues
- **Safe with `intr`**: User can interrupt hung operations

Alternative (`soft` mounts) would timeout and potentially lose data.

## Testing

### Role Test

```bash
# Dry run (check mode)
ansible-playbook roles/nas_mount/tests/test.yml --check --diff

# Apply locally
ansible-playbook roles/nas_mount/tests/test.yml --ask-become-pass
```

### Integration Test

```bash
# Apply to specific host
ansible-playbook local.yml -l rincewind --ask-become-pass

# Verify mount works
ssh rincewind 'ls /media/synology/public'
ssh rincewind 'mount | grep synology'
```

## References

- **fleet-422**: Epic for NAS auto-mount implementation
- **fleet-422.1**: Research comparing NFS vs SMB protocols
- **fleet-422.13**: Synology NFS export permission configuration
- **fleet-6o5**: ZeroTier peer discovery (provides hostname)

## Author

T.R. Fullhart (2026)
