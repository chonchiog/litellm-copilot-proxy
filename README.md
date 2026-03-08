# LiteLLM → GitHub Copilot Proxy for Claude Code

Route [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) through a local [LiteLLM](https://docs.litellm.ai/) proxy that forwards requests to GitHub Copilot's Claude models.

## Prerequisites

| Requirement | Notes |
|---|---|
| Python 3.10+ | `python3 --version` |
| GitHub Copilot subscription | Individual, Business, or Enterprise |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |

## Quick Start

```bash
# 1. Bootstrap (creates venv, installs litellm, generates master key)
chmod +x setup.sh start-proxy.sh test-proxy.sh run-claude.sh
./setup.sh

# 2. Start the proxy (leave this terminal open)
./start-proxy.sh

# 3. In a NEW terminal — test the proxy
./test-proxy.sh                    # uses copilot-opus-1m (primary)
./test-proxy.sh copilot-opus-fast  # uses copilot-opus-fast (fallback)

# 4. Run Claude Code through the proxy
./run-claude.sh                    # uses copilot-opus-1m
./run-claude.sh copilot-opus-fast  # uses copilot-opus-fast
```

## GitHub Device-Flow Login

On the **first request**, LiteLLM's GitHub Copilot provider will print a device code and URL in the proxy terminal:

```
Please visit https://github.com/login/device and enter code XXXX-XXXX to authenticate
```

1. Open the URL in your browser
2. Enter the code
3. Authorize the app
4. Credentials are cached locally (default: `~/.config/litellm/github_copilot/`)

Subsequent requests reuse the cached credentials automatically.

## Available Models

| Alias | LiteLLM Route | Notes |
|---|---|---|
| `copilot-opus-1m` | `github_copilot/claude-opus-4.6-1m` | Default — Opus 4.6 with 1M context |
| `copilot-opus` | `github_copilot/claude-opus-4.6` | Opus 4.6 (200K context) |
| `copilot-sonnet` | `github_copilot/claude-sonnet-4.6` | Sonnet 4.6 — faster, lighter |

### All Claude models available on your Copilot account

| Copilot API model ID | Name |
|---|---|
| `claude-opus-4.6-1m` | Claude Opus 4.6 (1M context) |
| `claude-opus-4.6` | Claude Opus 4.6 |
| `claude-sonnet-4.6` | Claude Sonnet 4.6 |
| `claude-sonnet-4.5` | Claude Sonnet 4.5 |
| `claude-opus-4.5` | Claude Opus 4.5 |
| `claude-sonnet-4` | Claude Sonnet 4 |
| `claude-haiku-4.5` | Claude Haiku 4.5 |

## Customisation

### Change the Copilot token directory

```bash
export GITHUB_COPILOT_TOKEN_DIR=~/.my-custom-dir
./start-proxy.sh
```

### Add more models

Edit `config.yaml` and add entries under `model_list`:

```yaml
  - model_name: copilot-sonnet
    litellm_params:
      model: github_copilot/claude-sonnet-4.6
```

Then restart the proxy and use `./run-claude.sh copilot-sonnet`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` on port 4000 | Make sure `./start-proxy.sh` is running |
| `Model not found` | Verify the alias in `config.yaml` matches what you pass to `--model` |
| Auth errors | Re-run `./test-proxy.sh` — it may trigger a new device-flow login |
| `copilot-opus-1m` not available | This model is listed in the Copilot API but may require specific plan access |

## Project Structure

```
litellm-copilot-proxy/
├── config.yaml        # LiteLLM model routing
├── setup.sh           # One-time bootstrap
├── start-proxy.sh     # Start the proxy server
├── test-proxy.sh      # Curl test (triggers GitHub login)
├── run-claude.sh      # Launch Claude Code via the proxy
├── .env               # Master key (auto-generated, git-ignored)
├── .env.example       # Template for .env
├── .gitignore         # Keeps secrets out of git
└── .venv/             # Python virtual environment
```
