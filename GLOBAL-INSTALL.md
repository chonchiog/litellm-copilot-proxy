# Running Claude Code with a Single Command

The `run-claude.sh` script (aliased as `claude-proxy`) handles everything — starting the proxy, launching Claude, and cleaning up when you're done. No need for multiple terminals.

## What happens when you run it

1. **Checks if the LiteLLM proxy is already running** on `localhost:4000`
2. **If not, starts it in the background** and waits up to 30 seconds for it to become healthy
3. **Launches Claude Code** connected to the proxy
4. **When you exit Claude, the proxy is automatically stopped** (only if the script started it — if the proxy was already running, it's left alone)

## Making it available globally as `claude-proxy`

By default you have to `cd` into the repo and run `./run-claude.sh`. To use it from anywhere:

```bash
# Create the symlink (one time)
mkdir -p ~/.local/bin
ln -sf "$(cd /path/to/litellm-copilot-proxy && pwd)/run-claude.sh" ~/.local/bin/claude-proxy

# Add to PATH if not already there — put this in ~/.zshrc (macOS) or ~/.bashrc (Linux)
export PATH="$HOME/.local/bin:$PATH"

# Reload your shell
source ~/.zshrc
```

The script resolves the symlink back to the real repo directory, so it always finds `.env`, `config.yaml`, and the Python virtualenv no matter where you call it from.

## Usage

```bash
claude-proxy                          # default model: copilot-opus-1m
claude-proxy copilot-sonnet           # pick a different model
claude-proxy copilot-opus             # another model
claude-proxy --print "hello world"    # flags pass through to Claude
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `command not found: claude-proxy` | Symlink directory isn't in your PATH — see setup above |
| `Proxy failed to start within 30s` | Check `proxy.log` in the repo directory |
| `Error: .env not found` | Run `./setup.sh` in the repo first |

## Uninstall

```bash
rm ~/.local/bin/claude-proxy
```
