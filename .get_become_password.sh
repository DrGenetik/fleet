#!/bin/sh

# Try 1Password first
if command -v op >/dev/null 2>&1; then
    PASS=$(op read "op://ServiceAccountAccess/Fleet ansible become_pass/$(hostname)" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$PASS"
        exit 0
    fi
fi

# Fallback to TTY prompt
echo "1Password lookup failed. Please enter BECOME password:" >&2

# Disable echo for secure input
stty -echo < /dev/tty
read -r PASS < /dev/tty
stty echo < /dev/tty
echo "" >&2 # Print newline to stderr after input

echo "$PASS"
