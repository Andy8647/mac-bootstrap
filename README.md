# mac-bootstrap

One-shot installer that reproduces my full environment on a fresh Apple Silicon Mac:
**Ghostty + fish + Starship + Catppuccin Mocha**, the modern CLI toolkit (eza, bat, ripgrep, fzf, zoxide, lazygit, yazi, neovim, …), **Claude Code** (+ the `claude-sk` DeepSeek/permafrost setup), and all my dotfiles.

This repo is the **imperative provisioner** (Homebrew, packages, Claude Code, permafrost). All actual config files live in [`Andy8647/dotfiles`](https://github.com/Andy8647/dotfiles) and are applied by **chezmoi** — a single source of truth, no symlink overlap.

## Install

From the native macOS Terminal on a fresh Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash
```

Force-overwrite existing configs without prompting (passed through to `chezmoi apply --force`):

```bash
curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash -s -- --force
```

> During the run, chezmoi prompts **once** for the DeepSeek API key (used by the
> `claude-sk` fish function). Enter a current, valid key — it's stored only in
> machine-local `~/.config/chezmoi/chezmoi.toml`, never committed.

## What it does

1. Installs Xcode Command Line Tools (GUI dialog — click "Install" and wait).
2. Installs Homebrew.
3. Clones this repo to `~/.local/share/mac-bootstrap`.
4. Runs `brew bundle` against [Brewfile](./Brewfile) (CLI tools, fonts, Ghostty, Chrome).
5. Installs **bun** and **Claude Code** (native).
6. Clones **permafrost** (DeepSeek proxy) to `~/Projects/permafrost`.
7. Runs `chezmoi init Andy8647 && chezmoi apply` — applies fish/ghostty/starship/nvim/`.claude`/claude-hud configs, and registers the chrome-devtools MCP.
8. Registers fish in `/etc/shells` and `chsh -s` to fish.

## After it finishes

- Launch `claude`, then `/plugin marketplace add jarrodwatts/claude-hud` and `/plugin install claude-hud` (its `config.json` is already in place).
- For `claude-sk`: start the proxy on demand with `~/Projects/permafrost/cli/permafrost wrap` (see its README).

## Update later

```bash
cd ~/.local/share/mac-bootstrap && git pull && ./post-install.sh   # tools
chezmoi update                                                     # dotfiles
```

## Scope

Imperative provisioning + dotfiles via chezmoi. Python toolchains
(`pyenv install`, `uv tool install …`) and `permafrost` configuration/startup
are intentionally left manual.
