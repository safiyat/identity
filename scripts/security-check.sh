#!/usr/bin/env bash
set -euo pipefail

# Scan all tracked files (excluding the security script itself and the .github workflow)
FILES=$(git ls-files | grep -vE '^(scripts/security-check\.sh|\.github/workflows/security-check\.yml)$' || true)

if [ -z "$FILES" ]; then
    exit 0
fi

FAILED=0

# 1. Check for Private Key Headers (SSH, PGP, RSA, EC, PKCS#8)
echo "Checking for private key blocks..."
if grep -rnE "BEGIN (OPENSSH |RSA |DSA |EC |PGP |ENCRYPTED )?PRIVATE KEY" $FILES; then
    echo "ERROR: Private key material detected! Remove it immediately."
    FAILED=1
fi

# 2. Check for Plaintext Email Addresses
echo "Checking for plaintext email addresses..."
# Matches standard email patterns while ignoring example.com placeholders in README/scripts
EMAIL_MATCHES=$(grep -rnEI "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" $FILES \
    | grep -vE "@(example\.com|users\.noreply\.github\.com|[a-zA-Z0-9.-]+\.local)\b" || true)

if [ -n "$EMAIL_MATCHES" ]; then
    echo "ERROR: Plaintext email address detected:"
    echo "$EMAIL_MATCHES"
    FAILED=1
fi

if [ "$FAILED" -ne 0 ]; then
    exit 1
fi

echo "Security check passed: No private keys or plaintext emails found."
