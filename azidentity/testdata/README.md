# Test data

- `test-certificate.pem`: an invented self-signed certificate and its
  unencrypted RSA 2048 private key, made only for these tests and never
  used anywhere else. It is valid nowhere and trusted by nothing. It
  exists because native Xo cannot generate RSA keys yet (std's
  `crypto.generate_key(r, Rsa)` is a KeyErr until prime generation
  lands); when it can, the test generates its key instead and this file
  goes away.

  Made on 2026-11-05 with:

  ```sh
  openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem \
    -days 3650 -subj "/CN=xo-azure-test-only"
  cat cert.pem key.pem > test-certificate.pem && rm cert.pem key.pem
  ```

  gitleaks ignores this one path only: `scripts/gitleaks-extra.toml`,
  which `scripts/check-public.sh` adds to the shared configuration.

- `test-legacy.pfx`, `test-nopass.pfx`, `test-aes.pfx`, `test-chain.pfx`,
  `test-ec.pfx` and `test-ca.pem`: invented test material, made only for
  these tests from `test-certificate.pem` (and, for `test-ca.pem` and
  `test-ec.pfx`, keys invented on the spot and thrown away) by
  `make-pfx.sh`, run on 2026-11-06 with LibreSSL 3.3.6. The password of
  every protected file is `xo-test-only`. They are valid nowhere and
  trusted by nothing. `govectors_run_test.xo` reads them as Go's
  azidentity ParseCertificates does; the Go program that wrote the
  expected lines read the same files.
  gitleaks's `pkcs12-file` rule flags every `.pfx`; the allowlist in
  `scripts/gitleaks-extra.toml` takes `test-*.pfx` in this directory
  only.
