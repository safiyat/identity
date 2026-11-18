# How to Verify a Signed PDF Document

This guide explains how to verify the cryptographic signature and integrity of a PDF document signed with **`pdf_signing.crt`**.

---

## Step 1: Download & Verify the Certificate Fingerprint

Before trusting the certificate, download `pdf_signing.crt` and confirm its SHA256 fingerprint matches the official fingerprint published in this repository.

```bash
# 1. Download the public certificate
curl -fsSL https://raw.githubusercontent.com/safiyat/identity/main/users/safiyat/pdf_signing.crt -o pdf_signing.crt

# 2. Print the SHA256 fingerprint
openssl x509 -in pdf_signing.crt -noout -fingerprint -sha256
```

Compare the output against the fingerprint listed in `README.md` before proceeding.

---

## Step 2: Verify the PDF Signature

Choose either the command-line method or one of the desktop PDF viewers below.

### Option A: Command Line (Using `pdfsig` — Linux / macOS)

The `pdfsig` utility (included with `poppler-utils`) verifies PDF signatures directly from your terminal.

1. **Install `poppler` (if not already installed):**
   * **macOS:** `brew install poppler`
   * **Ubuntu / Debian:** `sudo apt install poppler-utils`

2. **Create a temporary NSS certificate database and import `pdf_signing.crt`:**
   ```bash
   mkdir -p ~/.pki/nssdb
   certutil -d sql:\$HOME/.pki/nssdb -A -t "C,," -n "Safiyat PDF Signing" -i pdf_signing.crt
   ```

3. **Verify the signed PDF:**
   ```bash
   pdfsig -nssdir sql:\$HOME/.pki/nssdb signed_document.pdf
   ```
   * **Success:** Look for `Signature Validation: Signature is Valid.` and `Certificate Validation: Certificate is Trusted.`
   * **Tampered file:** If the PDF was modified after signing, `pdfsig` will report `Signature Validation: Digest Mismatch.`

---

### Option B: Adobe Acrobat Reader (Windows / macOS)

Because `pdf_signing.crt` is a self-signed certificate, Adobe Acrobat will initially display *"Signature validity is UNKNOWN"* until you add the certificate to your Trusted Identities.

1. Click Menu (Windows) or Acrobat (macOS) in the top-left corner, then select Preferences (or press Ctrl + K / Cmd + K).
2. Select Signatures from the left-hand category list.
3. Under the Identities & Trusted Certificates section, click More....
4. Select Trusted Certificates on the left, click Import, and click Browse to select `pdf_signing.crt` certificate file.
5. Highlight the imported contact in the top box, then select the specific certificate in the bottom box.
6. Click Trust (or Edit Trust). Check the box for Use this certificate as a trusted root. Check any additional permissions you need (such as Certified documents or Privileged system operations) and click OK.
7. Click Import to complete the setup, then close the settings windows.

Open the signed PDF file in Adobe Acrobat Reader now and the document should show up as signed and all signatures as valid.

---

### Option C: LibreOffice Draw / Writer (Windows / macOS / Linux)

1. **Import the certificate into your OS / NSS trust store:**
   * **Windows:** Double-click `pdf_signing.crt` → **Install Certificate...** → **Local Machine / Current User** → **Place all certificates in the following store** → select **Trusted Root Certification Authorities**.
   * **macOS:** Double-click `pdf_signing.crt` to open **Keychain Access**, locate the certificate, double-click it, expand **Trust**, and set **When using this certificate** to **Always Trust**.
   * **Linux:** Import into `~/.pki/nssdb` using the `certutil` command shown in **Option A**.
2. Open the signed PDF in **LibreOffice**.
3. Go to **File → Digital Signatures → Digital Signatures...** to view and confirm the valid signature badge.

---

### Option D: Programmatic Verification via Python (`pyhanko`)

If you want to verify a signed PDF in a Python script or CI/CD pipeline without installing system packages like `poppler`, use **`pyhanko`**.

1. **Install `pyhanko`:**
   ```bash
   python3 -m pip install pyhanko
   ```

2. **Verify via the `pyhanko` CLI:**
   Pass `pdf_signing.crt` as the trust root using `--trust`:
   ```bash
   pyhanko sign validate --trust pdf_signing.crt signed_document.pdf
   ```
   * **Success:** Outputs `INTACT:TRUSTED` (confirming both that the PDF bytes were not altered and that the signature chains to `pdf_signing.crt`).

3. **Verify inside a Python script:**
   ```python
   from pyhanko.keys import load_cert_from_pemder
   from pyhanko.pdf_utils.reader import PdfFileReader
   from pyhanko.sign.validation import validate_pdf_signature
   from pyhanko_certvalidator import ValidationContext

   # 1. Load the public certificate as the trusted root
   root_cert = load_cert_from_pemder("pdf_signing.crt")
   vc = ValidationContext(trust_roots=[root_cert])

   # 2. Open and validate the signed PDF
   with open("signed_document.pdf", "rb") as f:
       reader = PdfFileReader(f)
       if not reader.embedded_signatures:
           raise ValueError("No digital signatures found in this PDF.")

       sig = reader.embedded_signatures[0]
       status = validate_pdf_signature(sig, vc)

       print(f"Intact (Unmodified): {status.intact}")
       print(f"Trusted Certificate: {status.trusted}")
       print(f"Summary: {status.pretty_print_details()}")
   ```

---

## Troubleshooting

* **"Document has been altered or corrupted since it was signed":** The PDF file was modified after the signature was applied. Do not trust the contents of the file.
* **"Signature validity is UNKNOWN":** Your PDF viewer has not yet been configured to trust `pdf_signing.crt`. Follow the trust import steps above and re-validate.
