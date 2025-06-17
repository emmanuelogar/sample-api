#!/usr/bin/env bash
set -e

echo "✅ Starting K3s and tooling setup.."

### 1. Install K3s with Traefik disabled
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -

# Ensure kubeconfig is available
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "✅ K3s installed with Traefik disabled"

### 2. Install kubectx and kubens
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens
echo "✅ kubectx and kubens installed"

### 3. Install fzf and k9s
sudo apt-get update -y
sudo apt-get install -y fzf k9s
echo "✅ fzf and k9s installed"

### 4. Install Helm (if not already installed)
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "✅ Helm installed"
else
  echo "✅ Helm already installed"
fi

echo "🎉 Setup complete! K3s is running without an Ingress controller."
