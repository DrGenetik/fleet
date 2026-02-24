# Codebase Context for Agents

This is an Ansible configuration repository for managing a fleet of personal computers (mobile, workstations, servers). It automates system setup, package installation, and user configuration.

**Supported Operating Systems:**

- **Linux**: Debian/Ubuntu (primary), Arch Linux (partial support)
- **macOS**: Darwin via Homebrew
- **Package Managers**: apt, pacman, homebrew

## Quick Start for Agents

1. **Review this document** completely to understand the codebase structure and conventions
2. **Run `bd quickstart`** to learn beads issue tracking basics
3. **Run `bd ready --json`** to find available work
4. **Claim work** with `bd update <id> --status in_progress`
5. **Complete the task** following conventions in this document
6. **Close issue** with `bd close <id>`
7. **Follow "Landing the Plane"** procedures before ending session
8. **Repeat** - find next ready task

## Essential Commands

### Agent Tooling

The environment is configured with tools to assist AI agents and developers (installed via `mise`):

- **Ansible Language Server**: `npm:@ansible/ansible-language-server` - Provides syntax validation and autocompletion
- **GitHub MCP**: `npm:@modelcontextprotocol/server-github` - Enables GitHub interaction
- **Todoist MCP**: `npm:@doist/todoist-ai` - Todoist integration for task management
- **Ansible Lint**: `pipx:ansible-lint` - Linting for Ansible playbooks/roles
- **Markdownlint**: `npm:markdownlint-cli` - Documentation linting
- **Beads (`bd`)**: `go:github.com/steveyegge/beads/cmd/bd` - Issue tracking integrated into the repo
- **GitHub CLI (`gh`)**: For GitHub operations from command line
- **1Password CLI (`op`)**: Required for accessing vault passwords and become passwords

### Task Management (Mise)

This project uses **[mise](https://mise.jdx.dev/)** to manage development tasks and dependencies. Prefer these commands over running `ansible-playbook` directly when possible.

**CRITICAL**: All `mise` tasks that run Ansible now depend on the **1Password CLI (`op`)**. `mise` will install the tool, but you **must be logged in (`op signin`)** for the tasks to work.

- **Install dependencies**:

  ```bash
  mise run install-collections
  ```

  _Installs Ansible collections from `requirements.yml`._

- **Apply configuration locally**:

  ```bash
  mise run apply-local
  ```

  _Automatically targets the current hostname._

- **Dry run (Check mode + Diff)**:

  ```bash
  mise run dry-run-local
  ```

- **Run Linters**:

  ```bash
  mise run lint
  ```

  _Runs `ansible-lint` (default config), `markdownlint`, and `bd lint`._

- **Run Tests**:

  ```bash
  mise run test
  ```

  _Runs a dry-run test of the `base` role on localhost._

- **Secret Management**:
  - `mise run secrets:view`: View vaulted secrets.
  - `mise run secrets:edit`: Edit vaulted secrets.
  - `mise run secrets:rekey`: Rekey the vault.

### Manual Ansible Commands

If you need to bypass mise or run on remote hosts:

- **Run on a specific host**:

  ```bash
  ansible-playbook local.yml -l rincewind --ask-become-pass
  ```

- **Run locally (manual)**:

  ```bash
  ansible-playbook local.yml -l "$(hostname)" -c local --ask-become-pass
  ```

## Project Structure

- **`local.yml`**: The main playbook with three plays:
  1. Pre-run Setup: Updates package caches, installs collections
  2. Apply base role: Runs `base` role on all hosts
  3. Apply host-specific roles: Dynamically includes roles from `roles_to_run` variable
  4. Cleanup: Runs post-tasks (apt autoremove, autoclean)
- **`hosts`**: Static inventory file defining groups:
  - `[local]`: localhost
  - `[mobile]`: rincewind, dresden
  - `[workstation]`: jareth, constantine
  - `[server]`: minecraft
- **`roles/`**: Seven roles total:
  - `base`: Common system configuration (packages, firewall, sshd, zerotier)
  - `user_core`: User configuration (user creation, `mise` installation, `chezmoi` for dotfiles)
  - `printing_3d`: 3D printing tools and configuration
  - `sdr`: Software Defined Radio tools (hamradio-sdr, SDR++)
  - `meshtastic`: Meshtastic radio configuration
  - `reform`: MNT Reform mobile-specific configuration
  - `amateur_radio`: Amateur/ham radio tools
  - **Role Structure**: Standard Ansible structure (`tasks/main.yml`, `handlers/`, `defaults/main.yml`, `vars/`, `meta/`, `tests/`)
  - **Platform-Specific Tasks**: Roles use includes like `{{ ansible_facts.system | lower }}_install_packages.yml` to handle Linux vs Darwin differences
- **`group_vars/`**:
  - `all/`: Global variables directory (not a file!)
    - `vars.yml`: Non-sensitive global variables (e.g., `user_name: kayos`)
    - `secrets.yml`: Vault-encrypted sensitive variables
  - `mobile.yml`, `server.yml`, `workstation.yml`: Group-specific vars
- **`host_vars/`**: Host-specific variables, primarily `roles_to_run` list
- **`mise.toml`**: Task definitions and tool versions
- **`requirements.yml`**: Ansible Galaxy collections (`community.general`)
- **`.beads/`**: Issue tracking database (issues.jsonl, config.yaml, etc.)

## Key Patterns

### Dynamic Role Execution

Roles are assigned per-host via the `roles_to_run` list variable defined in `host_vars/<hostname>.yml`. The main playbook (`local.yml`) includes a play that iterates this list using `ansible.builtin.include_role`.

```yaml
# host_vars/rincewind.yml
roles_to_run:
  - printing_3d
  - amateur_radio
  - meshtastic
  - reform
  - sdr
```

**How it works**:

1. `local.yml` has a play named "Apply roles to hosts"
2. This play uses `ansible.builtin.include_role` with `loop: "{{ roles_to_run | default([]) }}"`
3. If a host doesn't define `roles_to_run`, it only gets the `base` role

### Platform-Specific Task Files

Roles use Ansible facts to include platform-specific tasks:

```yaml
# Example from base role
- name: "System | Install Base Packages"
  ansible.builtin.include_tasks: "{{ ansible_facts.system | lower }}_install_packages.yml"
```

This pattern allows files like:

- `linux_install_packages.yml` - Linux-specific installation
- `darwin_install_packages.yml` - macOS-specific installation
- `linux_enable_firewall.yml` - Linux firewall configuration (ufw)
- `darwin_enable_firewall.yml` - macOS firewall configuration

### OS-Specific Variable Loading

The `base` role loads OS-specific variables dynamically:

```yaml
- name: "System | Load OS Specific Variables"
  ansible.builtin.include_vars:
    dir: vars
    files_matching: "{{ item | lower }}.yml"
  loop:
    - "{{ ansible_facts.system }}" # Linux, Darwin
    - "{{ ansible_facts.os_family }}" # Debian, Archlinux
    - "{{ ansible_facts.distribution }}" # Ubuntu
```

Variables are layered with increasing specificity (system → os_family → distribution).

### User Configuration (Chezmoi)

User dotfiles are managed via **[chezmoi](https://www.chezmoi.io/)**, installed and initialized by the `base` role:

1. Install `mise` via curl script
2. Use `mise` to install `chezmoi` globally
3. Initialize chezmoi with GitHub repo: `chezmoi init DrGenetik`
4. Dotfiles are pulled from the configured repo

### Code Style & Linting

- **FQCN**: Use Fully Qualified Collection Names for modules (e.g., `ansible.builtin.apt` instead of `apt`).
- **Named Plays/Tasks**: All plays and tasks must have descriptive names. Capitalize names properly.
- **Copyright Headers**: Role files use `# Copyright (c) 2026 T.R. Fullhart. All Rights Reserved.` header.
- **Linting**:
  - `ansible-lint`: Uses Ansible's default configuration (no custom `.ansible-lint` file). Run with `mise run lint:ansible`.
  - `markdownlint`: Configured in `.markdownlint.json` (disables MD013 line length, allows duplicate headings in siblings). Run with `mise run lint:markdown`.
  - Combined: `mise run lint` runs both linters.

## Secret Management (Ansible Vault & 1Password)

- **Encryption**: Sensitive variables are encrypted using Ansible Vault in `group_vars/all/secrets.yml`.
- **Vault Password Source**: The vault password is fetched on-demand via `.get_vault_password.sh`, which uses the 1Password CLI (`op`) to read from the vault:

  ```bash
  op read "op://ServiceAccountAccess/Fleet ansible-vault/password"
  ```

- **Become Password Source**: Sudo passwords are fetched via `.get_become_password.sh`, which reads host-specific passwords:

  ```bash
  op read "op://ServiceAccountAccess/Fleet ansible become_pass/$(hostname)"
  ```

- **1Password CLI Requirement**: All local development requires an active `op` session. Run `op signin` before executing Ansible commands.
- **Configuration**: Both scripts are configured in `ansible.cfg`:
  - `vault_password_file = .get_vault_password.sh`
  - `become_password_file = .get_become_password.sh`

## Privacy & Security Best Practices

### Sensitive Data Management

**Never commit sensitive information** to the repository. This includes:

- Private network names, hostnames, or domain suffixes
- Private IP addresses or subnets (RFC 1918 ranges that could reveal network topology)
- API keys, tokens, or credentials
- Personal identifiable information

**Store sensitive values in 1Password** and reference them via Ansible lookups:

```yaml
# group_vars/all/vars.yml
zerotier_network_name: "{{ lookup('community.general.onepassword', 'item_id', vault='VaultName', field='field_name') }}"
```

**Use RFC 5737 test networks in documentation**:

- `198.51.100.0/24` (TEST-NET-2) - Reserved for documentation and examples
- `192.0.2.0/24` (TEST-NET-1) - Alternative documentation range
- `203.0.113.0/24` (TEST-NET-3) - Another alternative

**Use generic names in examples**:

- Hostnames: `workstation1`, `mobile1`, `server1`, `nas-server`
- Network names: `example_network`, `test_network`
- Domain suffixes: `example_network.zt`, `test.local`

### Removing Sensitive Data from Git History

If sensitive data was previously committed, use `git-filter-repo` to rewrite history:

1. **Install git-filter-repo**:

   ```bash
   mise use -g pipx:git-filter-repo
   mise install
   ```

2. **Create backup**:

   ```bash
   git clone --mirror /path/to/repo /path/to/repo-backup.git
   ```

3. **Create replacement file** (`replacements.txt`):

   ```text
   sensitive_hostname.domain==>generic_hostname.example
   192.168.1.0/24==>198.51.100.0/24
   secret_name==>example_name
   ```

   **Order matters**: List longest strings first to avoid partial replacements.

4. **Test on clone**:

   ```bash
   git clone /path/to/repo /tmp/repo-test
   cd /tmp/repo-test
   git-filter-repo --replace-text replacements.txt --force
   git log --all -S "sensitive_data"  # Should return nothing
   ```

5. **Apply to production repo**:

   ```bash
   cd /path/to/repo
   git-filter-repo --replace-text replacements.txt --force
   git remote add origin <url>
   git push --force --all
   git push --force --tags
   ```

6. **Update all clones**:

   ```bash
   git fetch --all
   git reset --hard origin/main
   ```

**⚠️ Warning**: This is a destructive operation. All collaborators must re-clone or reset their repositories after force push.

## Conventions & Gotchas

- **Issue Tracking**: Always capture identified next steps as new tasks in the `beads` system (`bd create ...`). **Never leave next steps as comments in code** or just as text in responses.
- **Task Integrity**: After creating or updating tasks, run `bd lint` to ensure required fields (like Acceptance Criteria) are present. Correct any errors before proceeding.
- **TODOs in Code**: Existing roles contain inline `# todo:` comments. These are acceptable as documentation of known issues, but new work should be tracked in beads instead.
- **`become` Keyword**: Some tasks (like `ansible.builtin.user`) require an explicit `become: true` even if the parent play already has `become` set. This is a nuance of Ansible privilege escalation.
- **User Variable**: The primary user is defined as `user_name` in `group_vars/all/vars.yml` (default: `kayos`).
- **`group_vars` Precedence**: **Critical Ansible behavior**: If a directory named `group_vars/all/` exists, Ansible will **ignore** a file named `group_vars/all.yml`. All variables for the `all` group must be placed in files _within_ `group_vars/all/` directory.
- **OS Support**: Primary targets are **Debian/Ubuntu** (`ansible_facts['os_family']|lower == 'debian'`). Darwin/macOS support exists via platform-specific task files.
- **Python Interpreter**: Explicitly set to `auto_silent` in `ansible.cfg` to avoid interpreter discovery warnings.
- **Prerequisites**: The `base` role ensures essential packages (`ansible-core`, `mise`, etc.) are installed on target systems.
- **Package Manager Detection**: Playbooks use `ansible_facts.pkg_mgr` to detect and handle apt, pacman, or homebrew.
- **Variable Merging**: `hash_behaviour` is set to `replace` (default), not `merge`.

## Common Tasks & Examples

### Adding a New Role

1. Create role structure: `mkdir -p roles/newrole/{tasks,defaults,vars,handlers,meta,tests}`
2. Create `roles/newrole/tasks/main.yml` with copyright header
3. Add platform-specific task files if needed (e.g., `linux_install.yml`, `darwin_install.yml`)
4. Define defaults in `roles/newrole/defaults/main.yml`
5. Add role to a host's `roles_to_run` list in `host_vars/<hostname>.yml`
6. Test with dry run: `mise run dry-run-local`
7. Create a test playbook in `roles/newrole/tests/test.yml`

### Adding Packages to Base Role

Packages are defined in OS-specific variable files in `roles/base/vars/`:

```yaml
# roles/base/vars/debian.yml
base_package_names:
  - ansible-core
  - build-essential
  - curl
  - git
  - zsh
  - newpackage # Add here
```

Categories of packages:

- `base_package_names`: Core system packages
- `base_sshd_package_names`: SSH and firewall packages
- `base_zerotier_package_names`: ZeroTier VPN packages
- `base_user_shell_package_names`: Shell-related packages
- `base_user_groups`: Groups to add the user to

### ZeroTier Peer Discovery

The base role automatically populates `/etc/hosts` with ZeroTier network member hostnames on every Ansible run:

**How it works:**

1. Clones [zerotier-scripts](https://github.com/KimTholstorf/zerotier-scripts) to `/usr/local/src/zerotier-scripts`
2. Installs `getnetworkmembers` script as `/usr/local/bin/zerotier-gethosts`
3. Queries ZeroTier Central API for network members using your API token
4. Creates entries like `198.51.100.193 nas-server.example_network.zt` (FQDN only)
5. Injects entries into `/etc/hosts` using Ansible's `blockinfile` module with marker comments

**Configuration variables:**

- `zerotier_api_token`: Retrieved from 1Password at `ServiceAccountAccess/Fleet ZeroTier Network ID/credential`
- `zerotier_network_id`: Retrieved from 1Password at `ServiceAccountAccess/Fleet ZeroTier Network ID/network_id`
- `zerotier_domain_suffix`: Default `zt`, creates FQDNs like `synology.zt`

**Prerequisites:**

- ZeroTier API token must be stored in 1Password
- Dependencies `curl` and `jq` are automatically installed by the base role
- Only runs on Linux hosts (no Darwin implementation currently)

**Example /etc/hosts entries:**

```text
# BEGIN ANSIBLE MANAGED BLOCK - ZeroTier Peers
198.51.100.102     workstation1.example_network.zt
198.51.100.204     mobile1.example_network.zt
198.51.100.206     workstation2.example_network.zt
198.51.100.86      server1.example_network.zt
198.51.100.193     nas-server.example_network.zt
# END ANSIBLE MANAGED BLOCK - ZeroTier Peers
```

This enables you to connect to peers using their FQDN: `ssh nas-server.example_network.zt` or `ping workstation1.example_network.zt`

### NAS Auto-Mount (fleet-422)

**Status:** Implemented (fleet-422.7, fleet-422.3)  
**Role:** nas_mount  
**Protocol:** NFSv4.1 via autofs

#### Configuration

- **NAS Hostname:** nas-server.example_network.zt (from ZeroTier discovery)
- **Share:** /volume1/Public → /media/synology/public
- **Mount Type:** On-demand (autofs)
- **Auto-unmount:** 300 seconds (5 minutes) after last access
- **Mount Options:** rw,hard,intr,nosuid,timeo=600,retrans=2,nfsvers=4.1,_netdev

#### Features

- No credentials required (NFS UID/GID mapping)
- Tolerates network interruptions (hard mount with interrupt)
- No boot delays (mounts on first access)
- Works over ZeroTier VPN
- Auto-unmounts after idle timeout (resource efficient)

#### Usage

Mount triggers automatically on first access:

```bash
# Access the share
ls /media/synology/public

# Files become available
cd /media/synology/public
```

#### Target Hosts

- **Mobile:** rincewind (tested, working), dresden (pending)
- **Workstations:** jareth (pending), constantine (pending)

#### Dependencies

- fleet-6o5: ZeroTier peer discovery (provides hostname resolution)
- fleet-422.13: Synology NFS export permissions (198.51.100.0/24 subnet allowed)

#### Troubleshooting

**Mount not appearing:**

```bash
# Check autofs service
systemctl status autofs  # Linux
automount -v              # macOS

# Check logs
journalctl -u autofs -n 50  # Linux
```

**Permission denied on write:**

- NFS uses UID/GID mapping from NAS
- Files owned by UID 1026 on NAS require matching UID locally
- Check file ownership: `ls -ln /media/synology/public`

### Working with Secrets

View encrypted secrets:

```bash
mise run secrets:view
```

Edit encrypted secrets:

```bash
mise run secrets:edit
```

Add new secret:

1. `mise run secrets:edit`
2. Add your variable in YAML format
3. Save and exit
4. Reference in tasks with `{{ secret_variable_name }}`

### Testing Changes

1. **Syntax check**: `ansible-playbook local.yml --syntax-check`
2. **Dry run**: `mise run dry-run-local` (shows what would change)
3. **Lint**: `mise run lint` (runs ansible-lint and markdownlint)
4. **Role test**: Update `roles/<role>/tests/test.yml` and run with check mode
5. **Apply locally**: `mise run apply-local` (actually applies changes)

### Adding a New Host

1. Add hostname to appropriate group in `hosts` file
2. Create `host_vars/<hostname>.yml`:

   ```yaml
   roles_to_run:
     - role1
     - role2
   ```

3. Ensure host is reachable via SSH or use `-c local` for localhost
4. Run playbook: `ansible-playbook local.yml -l <hostname>`

### Creating Platform-Specific Tasks

Pattern used throughout the codebase:

```yaml
# In roles/<role>/tasks/main.yml
- name: "Description"
  ansible.builtin.include_tasks: "{{ ansible_facts.system | lower }}_taskname.yml"
```

Then create both:

- `roles/<role>/tasks/linux_taskname.yml`
- `roles/<role>/tasks/darwin_taskname.yml`

### Variable Override Pattern

Host-specific overrides work via precedence (lowest to highest):

1. `roles/<role>/defaults/main.yml` - Role defaults
2. `roles/<role>/vars/<os>.yml` - OS-specific vars
3. `group_vars/all/vars.yml` - Global vars
4. `group_vars/<group>.yml` - Group vars (mobile, server, workstation)
5. `host_vars/<hostname>.yml` - Host-specific vars (highest priority)

Example override:

```yaml
# host_vars/rincewind.yml
sdr_release_override: sid # Override default release detection
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up.
2. **Run quality gates** (if code changed) - `mise run lint` (checks code, docs, AND beads integrity), `mise run test`.
3. **Update issue status** - Close finished work, update in-progress items.
4. **PUSH TO REMOTE** - This is MANDATORY:

   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```

5. **Clean up** - Clear stashes, prune remote branches.
6. **Verify** - All changes committed AND pushed.
7. **Hand off** - Provide context for next session.

**CRITICAL RULES:**

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## Beads Issue Tracking

This project uses [Beads (bd)](https://github.com/steveyegge/beads) for issue tracking.

### Core Rules

- Track ALL work in bd (never use markdown TODOs or comment-based task lists)
- Use `bd ready --json` to find available work
- Use `bd create` to track new issues/tasks/bugs
- Use `bd sync` at end of session to sync with git remote
- Git hooks auto-sync on commit/merge

### Quick Reference

```bash
bd ready --json                       # Show issues ready to work (no blockers)
bd list --status=open                 # List all open issues
bd create --title="..." --type=task   # Create new issue
bd update <id> --status=in_progress   # Claim work
bd close <id>                         # Mark complete
bd dep add <issue> <depends-on>       # Add dependency (blocks relationship)
bd sync                               # Sync with git remote
```

### Workflow

1. Check for ready work: `bd ready --json`
2. Claim an issue: `bd update <id> --status=in_progress`
3. Do the work following this document's conventions
4. Mark complete: `bd close <id>`
5. Sync: `bd sync` (or let git hooks handle it)

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Dependencies

Beads supports dependency tracking to ensure work is done in the correct order:

- **blocks**: Task B must complete before Task A can start
- **related**: Soft connection, doesn't block progress
- **parent-child**: Epic/subtask hierarchical relationship
- **discovered-from**: Auto-created when AI discovers related work

Use `bd dep tree <id>` to visualize dependency chains and `bd dep cycles` to detect circular dependencies.

### Advanced Commands

- `bd prime`: Load complete workflow context in AI-optimized format
- `bd ready --json`: Get ready issues in JSON format for programmatic access
- `bd show <id>`: Show full details of an issue including dependencies
- `bd dep add <id> <blocks-id>`: Add a blocking dependency

For detailed documentation, run `bd quickstart` or `bd --help`.

## Agent Roles

### Planning Role

We are in the role of product managers and senior software engineers doing planning and ticketing.

**Rules:**

1. **No Implementation**: We do not work on tasks; we only create, update, and refine them.
2. **Break Down Work**: If ready tasks are too complex, break them into simpler subtasks.
3. **Clarify**: If task bodies are vague, clarify them. Ask the user if requirements are ambiguous.
4. **Capture Everything**: File follow-up items, suggestions, and next steps as new tasks immediately.
5. **Include Quality Gates**: Ensure that Acceptance Criteria for tasks ALWAYS includes:
    - `mise run lint` passes (for all tasks with code or documentation changes)
    - `mise run test` passes (for all tasks with code changes)

### Worker Role

We are in the role of a task worker. A task worker is a senior software developer and follows these general steps for each development session:

1. **Review Context**: Review `AGENTS.md` to learn about the project and development guidelines.
2. **Select Work**: Gets a list of ready tasks (e.g., using `bd ready`).
3. **Plan**: **Crucial Step**: Iteractively review the task plan with the user _before_ starting implementation. Confirm understanding and approach.
4. **Execute**:
    - After the review and any modifications/clarifications, mark the task as `in_progress` and start working on it.
    - While working, if any issues not directly related to the task are found, stop work and add tasks for the issues.
5. **Verify & Deliver**:
    - **Run Quality Gates**: Ensure all quality gates pass _before_ committing any changes:
        - Run linting: `mise run lint` (checks code style, documentation, beads integrity)
        - Run tests: `mise run test` (validates playbook functionality)
    - A task is not complete until linting passes (`mise run lint`), tests pass (`mise run test`), work is committed to git, and pushed to the git remote.
6. **Follow-up**: New tasks are added for any follow-on items, issues, or suggestions.
