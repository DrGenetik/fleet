# Codebase Context for Agents

This is an Ansible configuration repository for managing a fleet of personal computers (laptops, workstations, servers). It automates system setup, package installation, and user configuration.

## Essential Commands

### Task Management (Mise)

This project uses **[mise](https://mise.jdx.dev/)** to manage development tasks and dependencies. Prefer these commands over running `ansible-playbook` directly when possible.

**CRITICAL**: All `mise` tasks that run Ansible now depend on the **1Password CLI (`op`)**. `mise` will install the tool, but you **must be logged in (`op signin`)** for the tasks to work.

- **Apply configuration locally**:

  ```bash
  mise run apply-local
  ```

  *Automatically targets the current hostname.*

- **Dry run (Check mode + Diff)**:

  ```bash
  mise run dry-run-local
  ```

- **Run Linters**:

  ```bash
  mise run lint
  ```

  *Runs `ansible-lint` and `markdownlint`.*

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

- **`local.yml`**: The main playbook.
- **`hosts`**: Static inventory file.
- **`roles/`**:
  - `base`: Common config (packages, user setup, `mise` installation, `chezmoi` for dotfiles).
  - Domain roles: `printing_3d`, `sdr`, `meshtastic`, `reform`, `amateur_radio`.
- **`group_vars/`**:
  - `all/`: Global variables.
    - `vars.yml`: Non-sensitive global variables (e.g., `user_name`).
    - `secrets.yml`: Vault-encrypted sensitive variables.
  - `laptop.yml`, `server.yml`, etc.: Group-specific vars.
- **`host_vars/`**: Host-specific variables (mostly `roles_to_run`).
- **`mise.toml`**: Task definitions and tool versions.

## Key Patterns

### Dynamic Role Execution

Roles are assigned per-host via the `roles_to_run` list variable defined in `host_vars/<hostname>.yml`. `local.yml` iterates this list to include roles dynamically.

```yaml
# host_vars/rincewind.yml
roles_to_run:
  - printing_3d
  - sdr
```

### User Configuration (Chezmoi)

User dotfiles are managed via **[chezmoi](https://www.chezmoi.io/)**, installed and initialized by the `base` role using `mise`.

### Code Style & Linting

- **FQCN**: Use Fully Qualified Collection Names for modules (e.g., `ansible.builtin.apt` instead of `apt`).
- **Named Plays/Tasks**: All plays and tasks must have descriptive names (capitalized).
- **Linting**:
  - `ansible-lint`: Configured in `.ansible-lint`. Checks for best practices.
  - `markdownlint`: Configured in `.markdownlint.json`. Checks documentation.

## Secret Management (Ansible Vault & 1Password)

- **Encryption**: Sensitive variables are encrypted using Ansible Vault in `group_vars/all/secrets.yml`.
- **Password Source**: The vault password is **not** stored on disk in a plaintext file. It is fetched on-demand by an executable script, `.get_vault_password.sh`.
- **1Password CLI**: This script uses the 1Password CLI (`op`) to read the secret from the shared vault. This means all local development requires an active `op` session. `mise` is configured to automatically install the `op` tool.

## Conventions & Gotchas

- **`become` Keyword**: Some tasks (like `ansible.builtin.user`) require an explicit `become: true` even if the parent play already has `become` set. This is a nuance of how Ansible applies privileges.
- **User Variable**: The primary user is defined as `user_name` in `group_vars/all/vars.yml` (default: `kayos`).
- **`group_vars` Precedence**: A critical Ansible behavior to be aware of: if a directory named `group_vars/all/` exists, Ansible will **ignore** a file named `group_vars/all.yml`. All variables for the `all` group must be placed in files *within* that directory. This was the root cause of an earlier `user_name is undefined` error.
- **OS Support**: Targets **Debian/Ubuntu** (`ansible_facts['os_family']|lower == 'debian'`).
- **Python Interpreter**: Explicitly set to `/usr/bin/python3` in `ansible.cfg` to resolve interpreter discovery warnings.
- **YAML Output**: The deprecated `yaml` callback was replaced with `stdout_callback = default` and `result_format = yaml` in `ansible.cfg` for modern, clean YAML output.
- **Prerequisites**: The `base` role ensures `ansible` and `mise` are installed on the target system.
