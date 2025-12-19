# Fleet Configuration

This repository contains the Ansible configuration for managing the fleet of personal computers (laptops, workstations, servers).

## 1. Bootstrapping with ansible-pull

To provision a machine for the first time (or update it without cloning the repo manually), use `ansible-pull`. This will clone the repository and apply the configuration matching the machine's hostname.

**Prerequisites**:

- `git` and `ansible` must be installed.
- The machine's hostname must match an entry in the `hosts` inventory file.

For interactive bootstrapping, you can provide the vault password when prompted:

```bash
ansible-pull -U https://github.com/DrGenetik/fleet.git -i hosts local.yml -l "$(hostname)"
```

For automated bootstrapping (e.g., via a script or cron job), you must place a vault password file on the remote machine (e.g., at `/root/.vault_password`) and reference it in the command.

## 2. Running Locally

If you have cloned the repository, you can run the playbook locally to apply changes.

### With mise (Recommended)

This project uses [mise](https://mise.jdx.dev/) to manage tasks. When you first run a `mise` command, it will automatically install the required tools, including the 1Password CLI.

**Prerequisites**:

- You must be logged into the correct 1Password account (`op signin`).

```bash
# Apply configuration to the current host
mise run apply-local
```

### Without mise

You can run the `ansible-playbook` command directly. You must limit execution to the current hostname to ensure the correct `host_vars` are loaded.

```bash
# Run on the current host (requires sudo password)
ansible-playbook local.yml -l "$(hostname)" -c local
```

## 3. Testing / Dry Run

To see what changes would be made without actually applying them (dry run), use the check mode.

### With mise

```bash
# Dry run with diff output
mise run dry-run-local
```

### Without mise

```bash
ansible-playbook local.yml -l "$(hostname)" -c local --check --diff
```

## 4. Linting

This project uses `ansible-lint` and `markdownlint` to ensure code quality.

### With mise

```bash
# Run all linters
mise run lint
```

## 5. Managing Secrets (Ansible Vault)

This repository uses [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) to encrypt sensitive variables. The vault password is not stored in this repository, but is instead fetched on-demand from 1Password using the `op` CLI.

**Prerequisites**:

- You must be logged into the correct 1Password account (`op signin`). `mise` will automatically install the `op` CLI tool for you.

### With mise

The following `mise` tasks are available to manage secrets:

```bash
# View the decrypted contents of the secrets file
mise run secrets:view

# Edit the secrets file (will be decrypted in your $EDITOR)
mise run secrets:edit

# Change the vault password (rekey the file)
# This will prompt you for the new password.
# IMPORTANT: After rekeying, you must update the password in 1Password.
mise run secrets:rekey
```
