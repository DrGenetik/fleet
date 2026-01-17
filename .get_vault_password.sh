#!/bin/sh
# Attempt to read from 1Password
if command -v op >/dev/null 2>&1; then
    PASS=$(op read "op://ServiceAccountAccess/Fleet ansible-vault/password" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$PASS"
        exit 0
    fi
fi

# Fallback for CI or when 1Password is unavailable/locked
# We return exit 0 so Ansible doesn't crash immediately on the script failure.
# We print a dummy password so Ansible attempts decryption (which will fail),
# rather than crashing on "empty password".
echo "Warning: Could not retrieve vault password from 1Password." >&2
echo "dummy-password-to-prevent-ansible-error"
exit 0
