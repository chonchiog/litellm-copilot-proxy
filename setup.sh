#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Creating Python virtual environment..."
python3.13 -m venv .venv
source .venv/bin/activate

echo "==> Installing litellm[proxy] and truststore..."
pip install --quiet 'litellm[proxy]' truststore

echo "==> Injecting truststore for corporate proxy SSL support..."
SITE_PACKAGES="$(python3 -c 'import site; print(site.getsitepackages()[0])')"
echo "import truststore; truststore.inject_into_ssl()" > "${SITE_PACKAGES}/truststore_inject.pth"

if [ ! -f .env ]; then
  KEY="sk-$(openssl rand -hex 32)"
  echo "LITELLM_MASTER_KEY=${KEY}" > .env
  echo "==> Generated master key and wrote .env"
else
  echo "==> .env already exists, skipping key generation"
fi

echo ""
echo "Setup complete! Next steps:"
echo "  1. Start the proxy:   ./start-proxy.sh"
echo "  2. Test the proxy:    ./test-proxy.sh   (triggers GitHub login on first use)"
echo "  3. Run Claude Code:   ./run-claude.sh"
