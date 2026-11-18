#!/usr/bin/env bash
set -euo pipefail

USER_DIR="users/safiyat"

echo "### SSH Keys & Certificates"
echo ""
echo "| Purpose | File | Algorithm | SHA256 Fingerprint |"
echo "| :--- | :--- | :--- | :--- |"

shopt -s nullglob

# 1. Process SSH public keys and certificates
for keyfile in "$USER_DIR"/*.pub; do
    key_type=$(awk '{print $1}' "$keyfile")
    fingerprint=$(ssh-keygen -lf "$keyfile" | awk '{print $2}')

    if [[ "$keyfile" == *"sign"* || "$keyfile" == *"-cert.pub" ]]; then
        purpose="Git Signing"
    elif [[ "$keyfile" == *"auth"* ]]; then
        purpose="Authentication"
    else
        purpose="General"
    fi

    echo "| **$purpose** | \`$keyfile\` | \`$key_type\` | \`$fingerprint\` |"
done

# 2. Process SSH Certificate Authority (CA) public keys
for cafile in ca/*.pub; do
    key_type=$(awk '{print $1}' "$cafile")
    fingerprint=$(ssh-keygen -lf "$cafile" | awk '{print $2}')
    echo "| **Signing CA** | \`$cafile\` | \`$key_type\` | \`$fingerprint\` |"
done

# 3. Process GPG public keys (omitting email/UID to prevent scraping)
gpg_files=("$USER_DIR"/*.asc)
if [ ${#gpg_files[@]} -gt 0 ]; then
    echo ""
    echo "### GPG / PGP Keys"
    echo ""
    echo "| Context | File | Algorithm | Full Fingerprint |"
    echo "| :--- | :--- | :--- | :--- |"

    for gpgfile in "${gpg_files[@]}"; do
        gpg_info=$(gpg --with-colons --import-options show-only --import "$gpgfile" 2>/dev/null)
        algo_code=$(echo "$gpg_info" | awk -F: '$1 == "pub" {print $4; exit}')
        fingerprint=$(echo "$gpg_info" | awk -F: '$1 == "fpr" {print $10; exit}')

        case "$algo_code" in
            1) algo="RSA" ;;
            17) algo="DSA" ;;
            19) algo="ECDSA" ;;
            22) algo="EdDSA (Ed25519)" ;;
            *) algo="PGP ($algo_code)" ;;
        esac

        formatted_fpr=$(echo "$fingerprint" | sed 's/.\{4\}/& /g' | sed 's/ $//')
        context=$(basename "$gpgfile" .asc)

        echo "| **$context** | \`$gpgfile\` | \`$algo\` | \`$formatted_fpr\` |"
    done
fi

# 4. Process X.509 Document / PDF Signing Certificates (.crt)
crt_files=("$USER_DIR"/*.crt)
if [ ${#crt_files[@]} -gt 0 ]; then
    echo ""
    echo "### X.509 Document Signing Certificates"
    echo ""
    echo "| Purpose | File | Subject | SHA256 Fingerprint |"
    echo "| :--- | :--- | :--- | :--- |"

    for crtfile in "${crt_files[@]}"; do
        subject=$(openssl x509 -in "$crtfile" -noout -subject -nameopt RFC2253 | sed 's/^subject=//')
        fingerprint=$(openssl x509 -in "$crtfile" -noout -fingerprint -sha256 | cut -d= -f2)

        echo "| **PDF / Document Signing** | \`$crtfile\` | \`$subject\` | \`$fingerprint\` |"
    done
fi

shopt -u nullglob
