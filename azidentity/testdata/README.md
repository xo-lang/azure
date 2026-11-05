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
