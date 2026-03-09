# Corporate Proxy SSL Workaround

This branch adds a workaround for **corporate environments** (e.g., Lockheed Martin) where a TLS-intercepting proxy causes Python SSL verification failures when LiteLLM tries to authenticate with GitHub Copilot.

## ELI15 — The Simple Version

Okay so imagine you're trying to text your friend (GitHub), but your school (Lockheed Martin) reads every message first. They open your texts, check them, then re-seal them with the school's own sticker before sending them out.

Your phone (Python) is like "wait... this sticker isn't from my friend, it's from the school... this is SUS 🚩" and **blocks the message**. That's the SSL error.

The thing is, your phone already knows the school is legit — it's saved in your contacts (macOS Keychain). But Python doesn't check your contacts. It only checks its own little list of trusted stickers (`certifi`), and the school's sticker isn't on it.

**The fix:** We installed `truststore`, which basically tells Python "yo, just check the contacts list on the phone instead of your own little list." Now Python sees the school's sticker, recognizes it, and lets the messages through. ✅

```
  Before:
  Python 🤖: "idk this sticker, BLOCKED" ❌

  After (with truststore):
  Python 🤖: "lemme check the phone's contacts..."
  macOS 📱:  "yeah that's the school, they're cool"
  Python 🤖: "aight bet, sending it through" ✅
```

---

## The Problem

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  LiteLLM Proxy ──── HTTPS ────► github.com/login/device/code    │
│       │                              ▲                           │
│       │                     ┌────────┴─────────┐                 │
│       │                     │  Corporate TLS   │                 │
│       │                     │  Intercepting    │                 │
│       │                     │  Proxy           │                 │
│       │                     │  (self-signed CA)│                 │
│       │                     └────────┬─────────┘                 │
│       ▼                              │                           │
│  Python ssl + certifi ──── ✗ REJECTS self-signed certificate     │
│  (only trusts public CAs)                                        │
│                                                                  │
│  Error: SSL: CERTIFICATE_VERIFY_FAILED                           │
│         certificate verify failed: self-signed certificate       │
│         in certificate chain                                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Corporate networks often route HTTPS traffic through a **TLS-intercepting proxy** that decrypts and re-encrypts traffic using its own Certificate Authority (CA). The corporate CA is installed in the **macOS Keychain** (so browsers and `curl` work fine), but Python uses its own bundled CA store via `certifi` — which **doesn't include the corporate CA**.

This means any outbound HTTPS from Python (including LiteLLM's GitHub device-flow authentication) fails with `CERTIFICATE_VERIFY_FAILED`.

## The Solution

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  .venv/lib/python3.13/site-packages/truststore_inject.pth        │
│  ┌────────────────────────────────────────────────────┐          │
│  │ import truststore; truststore.inject_into_ssl()    │          │
│  └────────────────────────────────────────────────────┘          │
│       │                                                          │
│       │  Auto-executes on every Python startup in the venv       │
│       │  (Python loads .pth files from site-packages at boot)    │
│       ▼                                                          │
│  Python ssl module ──► delegates to ──► macOS Keychain           │
│                                          (native trust store)    │
│                                              │                   │
│                                              ├─ ✓ Public CAs    │
│                                              └─ ✓ Corporate CA  │
│                                                                  │
│  LiteLLM ──► github.com  ✅ SSL verification passes             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

We use the [`truststore`](https://github.com/sethmlarson/truststore) package to make Python delegate SSL certificate verification to the **operating system's native trust store** (macOS Keychain on macOS, Windows Certificate Store on Windows, system CA on Linux).

This is the same concept as `--native-tls` in tools like `uvx` and `cargo`.

## How It Works (Step by Step)

```
                    Python Process Startup
                           │
                           ▼
             ┌─────────────────────────┐
             │  Python loads .pth files │
             │  from site-packages     │
             └────────────┬────────────┘
                          │
                          ▼
             ┌─────────────────────────┐
             │  truststore_inject.pth  │
             │  imports truststore and │
             │  calls inject_into_ssl()│
             └────────────┬────────────┘
                          │
                          ▼
             ┌─────────────────────────┐
             │  truststore monkey-     │
             │  patches ssl module to  │
             │  use OS trust store     │
             └────────────┬────────────┘
                          │
                          ▼
             ┌─────────────────────────┐
             │  LiteLLM starts,        │
             │  httpx/ssl now trusts   │
             │  corporate CA           │
             └────────────┬────────────┘
                          │
                          ▼
             ┌─────────────────────────┐
             │  GitHub device-flow     │
             │  auth succeeds ✅       │
             └─────────────────────────┘
```

## What Changed

Only **one file** was modified: `setup.sh`

| Change | Why |
|---|---|
| `python3` → `python3.13` | macOS ships Python 3.9; LiteLLM requires 3.10+ |
| Install `truststore` package | Provides native OS trust store integration for Python |
| Create `truststore_inject.pth` | Auto-injects truststore on every Python startup in the venv |

### The .pth trick

Python automatically processes `.pth` files in `site-packages` during interpreter startup. Lines starting with `import` are **executed as code**. This means:

```
# .venv/lib/python3.13/site-packages/truststore_inject.pth
import truststore; truststore.inject_into_ssl()
```

...runs **before any application code**, ensuring that every `httpx`, `requests`, or `urllib3` call in LiteLLM uses the OS trust store.

## Approaches Tried (and why they didn't work)

| Approach | Result |
|---|---|
| `SSL_CERT_FILE=/etc/ssl/cert.pem` | ❌ File exists but doesn't contain the corporate CA (macOS `curl` uses Keychain directly, not this file) |
| `REQUESTS_CA_BUNDLE=/etc/ssl/cert.pem` | ❌ Same issue — cert file lacks corporate CA |
| `sitecustomize.py` in venv site-packages | ❌ Shadowed by homebrew's system-level `sitecustomize.py` |
| `truststore_inject.pth` in venv site-packages | ✅ Works — `.pth` files are processed per-site, so the venv's copy runs correctly |

## End-to-End Flow

```
┌────────────┐     ┌───────────────────┐     ┌──────────────┐     ┌─────────────┐
│            │     │                   │     │  Corporate   │     │             │
│ Claude     │────►│ LiteLLM Proxy     │────►│  TLS Proxy   │────►│ GitHub      │
│ Code CLI   │     │ localhost:4000    │     │  (invisible) │     │ Copilot API │
│            │◄────│                   │◄────│              │◄────│             │
└────────────┘     └───────────────────┘     └──────────────┘     └─────────────┘
                          │
                    truststore makes
                    Python trust the
                    corporate CA ✅
```
