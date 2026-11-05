# Test data

- `test-certificate.pem`: a self-signed certificate and its unencrypted
  RSA 2048 private key, made for these tests with
  `openssl req -x509 -newkey rsa:2048 -nodes -subj "/CN=xo-azure-test-only"`.
  It is valid nowhere and trusted by nothing; it exists because native Xo
  cannot generate RSA keys yet. gitleaks ignores this one file
  (`.gitleaksignore`).
