# Public Cryptographic Identity

This repository hosts my public SSH keys, signing certificates, public GPG/PGP keys, and X.509 document-signing certificates for identity verification, Git commit/tag validation, and PDF signature verification.

## Contents

* [Repository Layout](#repository-layout)
* [Verification Instructions](#verification-instructions)
  * [1. Verify SSH-Signed Git Commits](#1-verify-ssh-signed-git-commits)
  * [2. Verify GPG-Signed Commits & Messages](#2-verify-gpg-signed-commits--messages)
  * [3. Verify Signed PDF Documents](#3-verify-signed-pdf-documents)
* [Key Fingerprints](#key-fingerprints)
  * [SSH Keys & Certificates](#ssh-keys--certificates)
  * [GPG / PGP Keys](#gpg--pgp-keys)
  * [X.509 Document Signing Certificates](#x509-document-signing-certificates)
* [Commit Integrity](#commit-integrity)

## Repository Layout

* **`users/safiyat/`** — Personal SSH public keys (`.pub`), signed certificates (`*-cert.pub`), GPG public keys (`.asc`), and X.509 public certificates (`.crt`).
* **`ca/`** — Public Certificate Authority (CA) keys used to sign short-lived certificates *(if applicable)*.
* **`scripts/`** — Helper script for generating key and certificate fingerprint tables.

## Verification Instructions

### 1. Verify SSH-Signed Git Commits
To verify my commits without exposing email addresses in this repository, fetch my signing key and map it to the commit author email locally:

```bash
# 1. Fetch the public signing key and build your local allowed_signers file
# Replace <commit-email> with the email shown in `git log` for my commits
KEY=\$(curl -fsSL https://raw.githubusercontent.com/safiyat/identity/main/users/safiyat/sign_ed25519.pub)
echo "<commit-email> namespaces=\"git\" \$KEY" >> ~/.ssh/allowed_signers

# 2. Configure Git to verify SSH signatures
git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers

# 3. Verify commit signatures
git log --show-signature
```

### 2. Verify GPG-Signed Commits & Messages
Import my public GPG keys into your local keyring:

```bash
# Import personal GPG key
curl -fsSL https://raw.githubusercontent.com/safiyat/identity/main/users/safiyat/pgp_personal.asc | gpg --import

# Import work GPG key
curl -fsSL https://raw.githubusercontent.com/safiyat/identity/main/users/safiyat/pgp_work.asc | gpg --import
```

### 3. Verify Signed PDF Documents
To verify PDFs signed with my self-signed X.509 certificate:

1. Download the public certificate:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/safiyat/identity/main/users/safiyat/pdf_signing.crt -o pdf_signing.crt
   ```
2. Verify its SHA256 fingerprint against the table below:
   ```bash
   openssl x509 -in pdf_signing.crt -noout -fingerprint -sha256
   ```
3. Import `pdf_signing.crt` into your PDF reader's **Trusted Certificates** list (e.g., **Adobe Acrobat Reader → Preferences → Signatures → Identities & Trusted Certificates**, or your OS certificate trust store for LibreOffice/Okular).

> **Need detailed instructions?** Follow the full **[PDF Signature Verification Guide](VERIFY_PDF.md)** for Adobe Acrobat Reader, LibreOffice, `pdfsig`, and Python (`pyhanko`) steps.

## Key Fingerprints

Always compare key fingerprints out-of-band before trusting any keys or certificates in this repository.

### SSH Keys & Certificates

| Purpose | File | Algorithm | SHA256 Fingerprint |
| :--- | :--- | :--- | :--- |
| **Git Signing** | `users/safiyat/sign_id_ecdsa.pub` | `ecdsa-sha2-nistp521` | `SHA256:GeqXL/Xnpna7AmF6iIwRr0KgF7SQRN56tw18FtabmBg` |
| **Git Signing** | `users/safiyat/sign_id_rsa.pub` | `ssh-rsa` | `SHA256:hThKjHHwOHrLChAJnGgOe8QbUTwEuaDxJQjCasS/IHg` |

### GPG / PGP Keys

| Context | File | Algorithm | Full Fingerprint |
| :--- | :--- | :--- | :--- |
| **pgp_personal** | `users/safiyat/pgp_personal.asc` | `RSA` | `8AB4 7045 9F78 6842 1510 F97D C2DA 0C4E 7CEA 7FA2` |
| **pgp_work_ve_** | `users/safiyat/pgp_work_ve_.asc` | `RSA` | `1DC9 7270 FF9D 694B 66DD 3F3B 858A D731 7E76 8E70` |

### X.509 Document Signing Certificates

| Purpose | File | Subject | SHA256 Fingerprint |
| :--- | :--- | :--- | :--- |
| **PDF / Document Signing** | `users/safiyat/pdf_signing.crt` | `CN=Md Safiyat Reza` | `69:18:81:17:40:A9:B8:C2:DD:B3:B0:78:09:F7:25:74:9B:43:90:69:61:43:08:5E:E9:AD:86:AA:9F:F4:3F:0F` |

## Commit Integrity

All commits to this repository are cryptographically signed. Verify commit signatures and key fingerprints before updating your local trust stores.
