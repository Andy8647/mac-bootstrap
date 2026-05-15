# mac-bootstrap

One-shot installer that reproduces my terminal environment on a fresh Apple Silicon Mac:
**Ghostty + fish + Starship + Catppuccin Mocha**, plus the modern CLI toolkit (eza, bat, ripgrep, fzf, zoxide, lazygit, yazi, neovim, …).

## Install

From the native macOS Terminal on a fresh Mac:

```bash
curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash
```

To overwrite existing `~/.config/{fish,ghostty,starship.toml}` (originals are backed up first):

```bash
curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash -s -- --force
```

## What it does

1. Installs Xcode Command Line Tools (GUI dialog — click "Install" and wait).
2. Installs Homebrew.
3. Clones this repo to `~/.local/share/mac-bootstrap`.
4. Runs `brew bundle` against [Brewfile](./Brewfile).
5. Symlinks configs into `~/.config/`.
6. Registers fish in `/etc/shells` (sudo password prompt) and `chsh -s` to fish (login password prompt).

## Update later

```bash
cd ~/.local/share/mac-bootstrap && git pull && ./post-install.sh
```

## Scope

Only the terminal layer. Python toolchains (`pyenv install`, `uv tool install …`), Neovim config, Claude Code setup, and other personal dotfiles are intentionally out of scope.
