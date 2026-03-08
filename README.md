# LiteLLM → GitHub Copilot Proxy for Claude Code

Use [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) powered by your [GitHub Copilot](https://github.com/features/copilot) subscription — no Anthropic API key needed.

This project sets up a local [LiteLLM](https://docs.litellm.ai/) proxy that translates Claude Code's requests and forwards them to GitHub Copilot's Claude models.

## How It Works

```
Claude Code  →  LiteLLM Proxy (localhost:4000)  →  GitHub Copilot API  →  Claude model
```

1. Claude Code sends requests to the local proxy (thinking it's talking to Anthropic)
2. LiteLLM translates and forwards them to GitHub Copilot's API
3. GitHub Copilot routes to the Claude model and returns the response
4. LiteLLM translates the response back to Claude Code's expected format

## Prerequisites

- **Python 3.10+** — `python3 --version`
- **GitHub Copilot subscription** — Individual, Business, or Enterprise
- **Claude Code CLI** — `npm install -g @anthropic-ai/claude-code`

## Quick Start

### 1. Clone and set up

```bash
git clone https://github.com/chonchiog/litellm-copilot-proxy.git
cd litellm-copilot-proxy
chmod +x setup.sh start-proxy.sh test-proxy.sh run-claude.sh
./setup.sh
```

This creates a Python virtual environment, installs LiteLLM, and generates a random master key in `.env`.

### 2. Start the proxy

```bash
./start-proxy.sh
```

Leave this terminal open — the proxy runs on `http://localhost:4000`.

### 3. Authenticate with GitHub (first time only)

In a **new terminal**, run:

```bash
./test-proxy.sh
```

The first time you do this, the **proxy terminal** will display:

```
Please visit https://github.com/login/device and enter code XXXX-XXXX to authenticate
```

1. Open the URL in your browser
2. Enter the code shown
3. Authorize the app

Credentials are cached locally at `~/.config/litellm/github_copilot/` — you won't need to log in again.

### 4. Run Claude Code

```bash
./run-claude.sh
```

That's it! Claude Code is now running through your GitHub Copilot subscription.

## Choosing a Model

The default model is `copilot-opus-1m` (Claude Opus 4.6 with 1M context). You can switch models by passing the alias as an argument:

```bash
./run-claude.sh copilot-opus      # Claude Opus 4.6 (200K context)
./run-claude.sh copilot-sonnet    # Claude Sonnet 4.6 (faster, lighter)
```

### Pre-configured aliases

| Alias | Copilot Model | Context Window |
|---|---|---|
| `copilot-opus-1m` | `claude-opus-4.6-1m` | 1M tokens |
| `copilot-opus` | `claude-opus-4.6` | 200K tokens |
| `copilot-sonnet` | `claude-sonnet-4.6` | 200K tokens |

### Adding more models

Edit `config.yaml` and add entries under `model_list`. For example, to add Haiku:

```yaml
  - model_name: copilot-haiku
    litellm_params:
      model: github_copilot/claude-haiku-4.5
```

Then restart the proxy and use `./run-claude.sh copilot-haiku`.

### All Claude models available via GitHub Copilot

| Model ID | Name |
|---|---|
| `claude-opus-4.6-1m` | Claude Opus 4.6 (1M context) |
| `claude-opus-4.6` | Claude Opus 4.6 |
| `claude-sonnet-4.6` | Claude Sonnet 4.6 |
| `claude-sonnet-4.5` | Claude Sonnet 4.5 |
| `claude-opus-4.5` | Claude Opus 4.5 |
| `claude-sonnet-4` | Claude Sonnet 4 |
| `claude-haiku-4.5` | Claude Haiku 4.5 |

> **Note:** Model availability depends on your Copilot plan. Some models (like `claude-opus-4.6-1m`) may require specific plan tiers.

## Customisation

### Custom Copilot token directory

```bash
export GITHUB_COPILOT_TOKEN_DIR=~/.my-custom-dir
./start-proxy.sh
```

### Manual setup (without scripts)

If you prefer not to use the helper scripts:

```bash
# Set up environment
python3 -m venv .venv
source .venv/bin/activate
pip install 'litellm[proxy]'

# Generate a master key
export LITELLM_MASTER_KEY="sk-$(openssl rand -hex 32)"

# Start the proxy
litellm --config ./config.yaml

# In another terminal, point Claude Code at the proxy
export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_AUTH_TOKEN="$LITELLM_MASTER_KEY"
claude --model copilot-opus-1m
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` on port 4000 | Make sure `./start-proxy.sh` is running in another terminal |
| `Model not found` | Verify the alias in `config.yaml` matches what you pass to `--model` |
| `UnsupportedParamsError` | Ensure `drop_params: true` is set in `litellm_settings` in `config.yaml` |
| Auth errors | Re-run `./test-proxy.sh` — it will trigger a new device-flow login |
| Model not available on your plan | Try a different model: `./run-claude.sh copilot-opus` or `copilot-sonnet` |

## Project Structure

```
litellm-copilot-proxy/
├── config.yaml        # LiteLLM model routing configuration
├── setup.sh           # One-time bootstrap (venv, install, key generation)
├── start-proxy.sh     # Start the LiteLLM proxy server
├── test-proxy.sh      # Test the proxy with a simple curl request
├── run-claude.sh      # Launch Claude Code through the proxy
├── .env               # Master key (auto-generated, git-ignored)
├── .env.example       # Template showing required env vars
├── .gitignore         # Keeps secrets and venv out of git
└── .venv/             # Python virtual environment (created by setup.sh)
```

## Credits

- [LiteLLM](https://github.com/BerriAI/litellm) — the proxy and GitHub Copilot provider
- [GitHub Copilot](https://github.com/features/copilot) — the model backend
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) — the CLI client
