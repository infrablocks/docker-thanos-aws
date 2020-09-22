# Docker Image - Thanos AWS

## Development

### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

### Generating example certs

To generate a TLS cert and key:

```
openssl req \
  -x509 \
  -newkey rsa:4096 \
  -keyout spec/fixtures/example-key.pem \
  -out spec/fixtures/example-cert.pem \
  -days 365 \
  -nodes \
  -subj '/CN=localhost'
```

To generate a CA cert and key for client certificates:

```
openssl genrsa \
  -out spec/fixtures/example-ca.key \
  2048
openssl req \
  -x509 \
  -new \
  -nodes \
  -key spec/fixtures/example-ca.key \
  -sha256 \
  -days 1024 \
  -out spec/fixtures/example-ca.pem \
  -subj "/C=UK/ST=Greater London/L=London/O=InfraBlocks/OU=Development/CN=localhost/emailAddress=maintainers@infrablocks.io"
```
