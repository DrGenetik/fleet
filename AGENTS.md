# Codebase Context for Agents

This is an Ansible configuration repository for managing a fleet of personal computers (laptops, workstations, servers). It automates system setup, package installation, and user configuration.

On agent start, after reviewing this document, run `bd quickstart` to learn the basics on how to use our task management system. Then do `bd ready --json` to discover a new ready task and work on that task following the rules under the "Landing the Plane" section. After completing a task, repeat this procedure.

## Essential Commands

### Agent Tooling

The environment is configured with tools to assist AI agents and developers:

- **Ansible Language Server**: Installed via `mise` (`npm:@ansible/ansible-language-server`). Provides syntax validation and autocompletion.
- **GitHub MCP**: Installed via `mise` (`npm:@modelcontextprotocol/server-github`). Enables agents to interact with GitHub repositories and issues.
- **Ansible Lint**: Installed via `mise` (`pipx:ansible-lint`). Run with `mise run lint`.
- **Beads**: Issue tracking integrated into the repo.

### Task Management (Mise)

This project uses **[mise](https://mise.jdx.dev/)** to manage development tasks and dependencies. Prefer these commands over running `ansible-playbook` directly when possible.

**CRITICAL**: All `mise` tasks that run Ansible now depend on the **1Password CLI (`op`)**. `mise` will install the tool, but you **must be logged in (`op signin`)** for the tasks to work.

- **Install dependencies**:

  ```bash
  mise run install-collections
  ```

  *Installs Ansible collections from `requirements.yml`.*

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

  *Runs `ansible-lint` (default config) and `markdownlint`.*

- **Run Tests**:

  ```bash
  mise run test
  ```

  *Runs a dry-run test of the `base` role on localhost.*

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

- **`local.yml`**: The main playbook.
- **`hosts`**: Static inventory file.
- **`roles/`**:
  - `base`: Common config (packages, user setup, `mise` installation, `chezmoi` for dotfiles).
  - Domain roles: `printing_3d`, `sdr`, `meshtastic`, `reform`, `amateur_radio`.
  - **Role Structure**: Standard Ansible structure (`tasks/`, `handlers/`, `defaults/`, `vars/`, `meta/`, `tests/`).
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
  - `ansible-lint`: Uses default configuration. Checks for best practices.
  - `markdownlint`: Configured in `.markdownlint.json`. Checks documentation.

## Secret Management (Ansible Vault & 1Password)

- **Encryption**: Sensitive variables are encrypted using Ansible Vault in `group_vars/all/secrets.yml`.
- **Password Source**: The vault password is **not** stored on disk in a plaintext file. It is fetched on-demand by an executable script, `.get_vault_password.sh`.
- **1Password CLI**: This script uses the 1Password CLI (`op`) to read the secret from the shared vault. This means all local development requires an active `op` session. `mise` is configured to automatically install the `op` tool.

## Conventions & Gotchas

- **Next Steps**: Always capture identified next steps as new tasks in the `beads` system (`bd create ...`). Do not leave next steps as comments in code or just text in the final response.
- **`become` Keyword**: Some tasks (like `ansible.builtin.user`) require an explicit `become: true` even if the parent play already has `become` set. This is a nuance of how Ansible applies privileges.
- **User Variable**: The primary user is defined as `user_name` in `group_vars/all/vars.yml` (default: `kayos`).
- **`group_vars` Precedence**: A critical Ansible behavior to be aware of: if a directory named `group_vars/all/` exists, Ansible will **ignore** a file named `group_vars/all.yml`. All variables for the `all` group must be placed in files *within* that directory.
- **Prerequisites**: The `base` role ensures `ansible` and `mise` are installed on the target system.
- **Variable Merging**: `hash_behaviour` is set to `replace` (default), not `merge`.
- **Outputs**: Ansible is configured to output YAML (`result_format = yaml` in `ansible.cfg`).

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up.
2. **Run quality gates** (if code changed) - `mise run lint`, `mise run test`.
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

- Work is NOT complete until `git push` succeeds.
- NEVER stop before pushing - that leaves work stranded locally.
- NEVER say "ready to push when you are" - YOU must push.
- If push fails, resolve and retry until it succeeds.
