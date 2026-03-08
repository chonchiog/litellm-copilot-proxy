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

MODEL="${1:-copilot-opus-1m}"

echo "Testing model: ${MODEL}"
echo "  (On first use, check the LiteLLM proxy terminal for GitHub device-flow login instructions)"
echo ""

curl -s http://localhost:4000/v1/messages \
  -H "Authorization: Bearer ${LITELLM_MASTER_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL}\",
    \"max_tokens\": 300,
    \"messages\": [
      {\"role\": \"user\", \"content\": \"Say hello in one sentence.\"}
    ]
  }" | python3 -m json.tool

echo ""
echo "If the request failed, check the proxy terminal for errors."
