#!/bin/sh

# 1. Fetch JWKS JSON
JWK_JSON=$(curl -s https://token.actions.githubusercontent.com/.well-known/jwks) || {
  echo "Failed to fetch JWKS JSON" >&2
  exit 1
}

# 2. Extract the first certificate (x5c[0]) from the first key that has it
X5C=$(echo "$JWK_JSON" | jq -r '.keys[] | select(.x5c) | .x5c[0]' | head -n1) || {
  if [ -z "$X5C" ]; then
    echo "No x5c certificate found in JWKS" >&2
    exit 1
  fi
}

# 3. Wrap it in certificate delimiters
cat <<EOF > github.crt
-----BEGIN CERTIFICATE-----
$X5C
-----END CERTIFICATE-----
EOF

# 4. Extract public key from certificate
openssl x509 -in github.crt -pubkey -noout > github_pubkey.pem

# 5. Base64-encode without newlines
BASE64_KEY=$(base64 -w0 github_pubkey.pem)

# Output as JSON for Terraform external data source
jq -n --arg key "$BASE64_KEY" '{github_oidc_base64_key: $key}'