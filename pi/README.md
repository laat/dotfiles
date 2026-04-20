# pi agent

Configuration and extensions for [pi](https://github.com/nickarbone/pi-coding-agent).

## Setup

```sh
stow --restow --no-folding --stow pi
cd ~/.pi/agent/extensions/sandbox && npm install
```

## models.json

`~/.pi/agent/models.json` is not tracked (contains API keys). Create it manually:

```json
{
  "providers": {
    "litellm": {
      "baseUrl": "https://...",
      "api": "openai-completions",
      "apiKey": "sk-...",
      "models": []
    }
  }
}
```

## What's included

- **settings.json** — default provider, model, and thinking level
- **extensions/sandbox.json** — sandbox policy (allowed domains, filesystem rules)
- **extensions/sandbox/** — OS-level sandboxing extension for bash commands
