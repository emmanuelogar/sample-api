#!/bin/bash

set -e

# Config
NAMESPACE="vault"
RELEASE_NAME="vault"
SECRET_NAME="${RELEASE_NAME}-vault-keys"

echo "🚀 Installing Vault via Helm..."
helm install "$RELEASE_NAME" hashicorp/vault -n "$NAMESPACE" --set injector.enabled=true --set csi.enabled=false --wait

VAULT_POD=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=vault -o jsonpath="{.items[0].metadata.name}")
echo "Vault Pod: $VAULT_POD"

echo "🔍 Checking if Vault is already initialized..."
INIT_STATUS=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault status -format=json | jq .initialized)

if [ "$INIT_STATUS" == "false" ]; then
  echo "⚙️ Initializing Vault..."
  INIT_OUTPUT=$(kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault operator init -format=json -key-shares=5 -key-threshold=3)

  echo "🔐 Saving unseal keys and root token to Kubernetes Secret..."
  kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
    --from-literal=init-output="$INIT_OUTPUT"
else
  echo "✅ Vault is already initialized. Skipping initialization."
fi

echo "🔓 Unsealing Vault..."
INIT_JSON=$(kubectl get secret -n "$NAMESPACE" "$SECRET_NAME" -o jsonpath="{.data.init-output}" | base64 -d)

UNSEAL_KEYS=$(echo "$INIT_JSON" | jq -r '.unseal_keys_b64[0,1,2]')

for KEY in $UNSEAL_KEYS; do
  echo " - Applying unseal key..."
  kubectl exec -n "$NAMESPACE" "$VAULT_POD" -- vault operator unseal "$KEY" > /dev/null
done

echo "✅ Vault unsealed successfully!"

exit 0

