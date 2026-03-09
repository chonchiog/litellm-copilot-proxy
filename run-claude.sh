#!/usr/bin/env bash
set -euo pipefail

# Resolve symlinks so the script works when invoked via a symlink (e.g. /usr/local/bin/claude-proxy)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
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

STARTED_PROXY=false

# Start the LiteLLM proxy in the background if it isn't already running
if ! curl -s --max-time 2 http://localhost:4000/health >/dev/null 2>&1; then
  echo "Starting LiteLLM proxy in the background..."
  source "$SCRIPT_DIR/.venv/bin/activate"
  export GITHUB_COPILOT_TOKEN_DIR="${GITHUB_COPILOT_TOKEN_DIR:-$HOME/.config/litellm/github_copilot}"
  nohup litellm --config "$SCRIPT_DIR/config.yaml" >"$SCRIPT_DIR/proxy.log" 2>&1 &
  PROXY_PID=$!
  STARTED_PROXY=true
  echo "  Proxy PID: $PROXY_PID (log: $SCRIPT_DIR/proxy.log)"

  # Wait for the proxy to become healthy
  for i in $(seq 1 30); do
    if curl -s --max-time 2 http://localhost:4000/health >/dev/null 2>&1; then
      echo "  Proxy is ready."
      break
    fi
    if ! kill -0 "$PROXY_PID" 2>/dev/null; then
      echo "Error: Proxy exited unexpectedly. Check $SCRIPT_DIR/proxy.log" >&2
      exit 1
    fi
    sleep 1
  done

  if ! curl -s --max-time 2 http://localhost:4000/health >/dev/null 2>&1; then
    echo "Error: Proxy failed to start within 30s. Check $SCRIPT_DIR/proxy.log" >&2
    exit 1
  fi
fi

# Kill the proxy when Claude exits (only if we started it)
cleanup() {
  if [ "$STARTED_PROXY" = true ] && kill -0 "$PROXY_PID" 2>/dev/null; then
    echo "Stopping LiteLLM proxy (PID $PROXY_PID)..."
    kill "$PROXY_PID" 2>/dev/null
    wait "$PROXY_PID" 2>/dev/null
  fi
}
trap cleanup EXIT

# Default to copilot-opus-1m; pass a different model name as $1 to override.
# Examples:
#   claude-proxy                     → copilot-opus-1m
#   claude-proxy copilot-opus        → copilot-opus
#   claude-proxy copilot-sonnet      → copilot-sonnet
# First non-flag argument is the model name; default to copilot-opus-1m
if [[ "${1:-}" != "" && "${1:-}" != -* ]]; then
  MODEL="$1"
  shift
else
  MODEL="copilot-opus-1m"
fi

claude --model "${MODEL}" "$@"
