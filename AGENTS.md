# Codebase Context for Agents

This is an Ansible configuration repository for managing a fleet of personal computers (laptops, workstations, servers). It automates system setup, package installation, and user configuration.

## Essential Commands

### Task Management (Mise)

This project uses **[mise](https://mise.jdx.dev/)** to manage development tasks and dependencies. Prefer these commands over running `ansible-playbook` directly when possible.

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
  - `base`: Common config (packages, user setup, `mise` installation).
  - Domain roles: `3d-printing`, `sdr`, `meshtastic`, `reform`, `amateur-radio`.
- **`group_vars/`**:
  - `all.yml`: Global variables (e.g., `user_name`).
  - `laptop.yml`, `server.yml`, etc.: Group-specific vars.
- **`host_vars/`**: Host-specific variables (mostly `roles_to_run`).
- **`mise.toml`**: Task definitions and tool versions.

## Key Patterns

### Dynamic Role Execution

Roles are assigned per-host via the `roles_to_run` list variable defined in `host_vars/<hostname>.yml`. `local.yml` iterates this list to include roles dynamically.

```yaml
# host_vars/rincewind.yml
roles_to_run:
  - 3d-printing
  - sdr
```

### Code Style & Linting

- **FQCN**: Use Fully Qualified Collection Names for modules (e.g., `ansible.builtin.apt` instead of `apt`).
- **Named Plays/Tasks**: All plays and tasks must have descriptive names (capitalized).
- **Linting**:
  - `ansible-lint`: Configured in `.ansible-lint`. Checks for best practices.
  - `markdownlint`: Configured in `.markdownlint.json`. Checks documentation.

## Conventions & Gotchas

- **Role Naming**: Role names in this project use hyphens (e.g., `3d-printing`), which conflicts with the default `role-name` linter rule. This rule has been disabled in `.ansible-lint`.
- **`become` Keyword**: Some tasks (like `ansible.builtin.user`) require an explicit `become: true` even if the parent play already has `become` set. This is a nuance of how Ansible applies privileges.
- **User Variable**: The primary user is defined as `user_name` in `group_vars/all.yml` (default: `kayos`).
- **OS Support**: Targets **Debian/Ubuntu** (`ansible_facts['os_family']|lower == 'debian'`).
- **Python Interpreter**: Explicitly set to `/usr/bin/python3` in `ansible.cfg` to resolve interpreter discovery warnings.
- **YAML Output**: The deprecated `yaml` callback was replaced with `stdout_callback = default` and `result_format = yaml` in `ansible.cfg` for modern, clean YAML output.
- **Prerequisites**: The `base` role ensures `ansible` and `mise` are installed on the target system.
