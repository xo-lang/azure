#!/bin/sh
# Makes the .pfx test files from test-certificate.pem (an invented
# certificate and key, README.md). Every file here is invented test
# material, valid nowhere. The test password is xo-test-only.
# Run from this directory with LibreSSL or OpenSSL 1.1 (whose pkcs12
# -export defaults are Go's: 40 bit RC2 for certificates, 3DES for keys).
set -eu
PW=xo-test-only
# an invented CA certificate (its key is thrown away)
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out test-ca.pem \
  -days 3650 -subj "/CN=xo-azure-test-only-ca"
rm ca.key
openssl pkcs12 -export -in test-certificate.pem -inkey test-certificate.pem \
  -passout pass:$PW -out test-legacy.pfx
openssl pkcs12 -export -in test-certificate.pem -inkey test-certificate.pem \
  -passout pass: -out test-nopass.pfx
openssl pkcs12 -export -in test-certificate.pem -inkey test-certificate.pem \
  -passout pass:$PW -keypbe AES-256-CBC -certpbe AES-256-CBC -out test-aes.pfx
openssl pkcs12 -export -in test-certificate.pem -inkey test-certificate.pem \
  -certfile test-ca.pem -passout pass:$PW -out test-chain.pfx
# an invented EC P-256 key and certificate in a .pfx (Go reads its key as
# an EC PRIVATE KEY block, which ParseCertificates skips)
openssl ecparam -name prime256v1 -genkey -noout -out ec.key
openssl req -x509 -new -key ec.key -out ec.pem -days 3650 -subj "/CN=xo-azure-test-only-ec"
openssl pkcs12 -export -in ec.pem -inkey ec.key -passout pass:$PW -out test-ec.pfx
rm ec.key ec.pem
