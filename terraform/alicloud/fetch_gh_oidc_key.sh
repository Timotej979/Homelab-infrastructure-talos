#!/bin/bash

CERT_FILE=$(mktemp)

# Step 1: Fetch TLS cert; on failure, print error to stderr and exit
if ! openssl s_client -connect token.actions.githubusercontent.com:443 -servername token.actions.githubusercontent.com < /dev/null 2>/dev/null \
  | openssl x509 -outform PEM > "$CERT_FILE"; then
  echo "[ERROR] Failed to retrieve certificate from GitHub OIDC issuer." >&2
  rm -f "$CERT_FILE"
  exit 1
fi

# Step 2: Extract SHA1 fingerprint; on failure, print error to stderr and exit
FINGERPRINT=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha1 2>/dev/null | sed 's/.*=//;s/://g' || true)
rm -f "$CERT_FILE"

if [[ -z "$FINGERPRINT" ]]; then
  echo "[ERROR] Failed to extract fingerprint from certificate." >&2
  exit 1
fi

if [[ ! "$FINGERPRINT" =~ ^[a-fA-F0-9]{40}$ ]]; then
  echo "[ERROR] Extracted fingerprint is not a valid SHA1 hash: $FINGERPRINT" >&2
  exit 1
fi

# Step 3: Output JSON only to stdout
jq -n --arg fp "$FINGERPRINT" '{"fingerprints": $fp}'