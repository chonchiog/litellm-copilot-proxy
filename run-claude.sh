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

export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_AUTH_TOKEN="${LITELLM_MASTER_KEY}"
export DISABLE_NON_ESSENTIAL_MODEL_CALLS="1"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"

# Default to copilot-opus-1m; pass a different model name as $1 to override.
# Examples:
#   ./run-claude.sh                     → copilot-opus-1m
#   ./run-claude.sh copilot-opus        → copilot-opus
#   ./run-claude.sh copilot-sonnet      → copilot-sonnet
MODEL="${1:-copilot-opus-1m}"
shift 2>/dev/null || true

exec claude --model "${MODEL}" "$@"
