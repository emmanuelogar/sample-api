#!/bin/bash

set -e

# Config
NAMESPACE="vault"
RELEASE_NAME="vault"
SECRET_NAME="${RELEASE_NAME}-vault-keys"

echo "🔍 Locating Vault pod..."
VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath="{.items[0].metadata.name}")

if [ -z "$VAULT_POD" ]; then
  echo "❌ Error: Vault pod not found in namespace '$NAMESPACE'."
  exit 1
fi
echo "✅ Vault Pod: $VAULT_POD"

echo "🔍 Checking if Vault is already initialized..."
INIT_STATUS=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault status -format=json | jq .initialized)

if [ "$INIT_STATUS" == "false" ]; then
  echo "⚙️ Initializing Vault..."
  INIT_OUTPUT=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault operator init -format=json -key-shares=5 -key-threshold=3)

  echo "🔐 Saving unseal keys and root token to Kubernetes Secret..."
  kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
    --from-literal=init-output="$INIT_OUTPUT"
else
  echo "✅ Vault is already initialized."
fi

echo "🔍 Checking if unseal keys secret exists..."
if ! kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" &> /dev/null; then
  echo "❌ Error: Vault is initialized but secret $SECRET_NAME not found. Cannot unseal."
  exit 1
fi

echo "🔓 Unsealing Vault..."
INIT_JSON=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.init-output}" | base64 -d)
UNSEAL_KEYS=$(echo "$INIT_JSON" | jq -r '.unseal_keys_b64[0,1,2]')

for KEY in $UNSEAL_KEYS; do
  echo " - Applying unseal key..."
  kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault operator unseal "$KEY" > /dev/null
done

echo "✅ Vault unsealed successfully!"

ROOT_TOKEN=$(echo "$INIT_JSON" | jq -r '.root_token')
echo "🎯 Root token: $ROOT_TOKEN"

exit 0