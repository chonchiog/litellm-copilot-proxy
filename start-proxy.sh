#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
  echo "Error: .env not found. Run ./setup.sh first." >&2
  exit 1
fi

set -a
source .env
set +a

source .venv/bin/activate

# Optionally customise where Copilot tokens are stored
export GITHUB_COPILOT_TOKEN_DIR="${GITHUB_COPILOT_TOKEN_DIR:-$HOME/.config/litellm/github_copilot}"

echo "Starting LiteLLM proxy on http://localhost:4000 ..."
echo "  Models:"
echo "    copilot-opus-1m  → github_copilot/claude-opus-4.6-1m"
echo "    copilot-opus     → github_copilot/claude-opus-4.6"
echo "    copilot-sonnet   → github_copilot/claude-sonnet-4.6"
echo ""

litellm --config ./config.yaml
