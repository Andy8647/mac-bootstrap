#!/usr/bin/env bash
#
# Runs after install.sh has bootstrapped Homebrew and cloned the repo.
# Installs the Brewfile, sets up Claude Code + permafrost, applies all
# dotfiles via chezmoi, and switches the login shell to fish.
#
# Config files (fish, ghostty, starship, nvim, .claude, claude-hud, ...) are
# owned by chezmoi (github.com/Andy8647/dotfiles), NOT symlinked from this repo.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/log.sh
source "$REPO_ROOT/lib/log.sh"

DOTFILES_REPO="${MAC_BOOTSTRAP_DOTFILES:-Andy8647}"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

command -v brew >/dev/null || log::die "Homebrew missing — run install.sh first."

# --- brew bundle ----------------------------------------------------------
log::step "Installing packages from Brewfile"
brew bundle --file="$REPO_ROOT/Brewfile"
log::ok "Brew bundle complete."

BREW_PREFIX="$(brew --prefix)"
FISH_BIN="$BREW_PREFIX/bin/fish"

# --- bun (official installer) --------------------------------------------
log::step "Installing bun"
if [[ -x "$HOME/.bun/bin/bun" ]]; then
  log::ok "Already installed at ~/.bun/bin/bun ($("$HOME/.bun/bin/bun" --version))."
else
  bun_installer="$(mktemp -t bun-install)"
  trap 'rm -f "$bun_installer"' EXIT
  if ! curl -fsSL --retry 3 --retry-delay 2 https://bun.sh/install -o "$bun_installer"; then
    log::die "Failed to download bun installer. Check your network and re-run."
  fi
  bash "$bun_installer"
  [[ -x "$HOME/.bun/bin/bun" ]] \
    || log::die "bun binary not found at ~/.bun/bin/bun after install."
  log::ok "bun installed."
fi

# --- Claude Code (native installer) --------------------------------------
# Installed BEFORE chezmoi apply: a chezmoi run_onchange script registers the
# chrome-devtools MCP via `claude mcp`, and silently skips if claude is absent.
log::step "Installing Claude Code"
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
  log::ok "Already installed ($(claude --version 2>/dev/null | head -1))."
else
  claude_installer="$(mktemp -t claude-install)"
  trap 'rm -f "$claude_installer"' EXIT
  if ! curl -fsSL --retry 3 --retry-delay 2 https://claude.ai/install.sh -o "$claude_installer"; then
    log::die "Failed to download Claude Code installer. Check your network and re-run."
  fi
  bash "$claude_installer"
  command -v claude >/dev/null 2>&1 \
    || log::die "claude not found on PATH after install (expected ~/.local/bin/claude)."
  log::ok "Claude Code installed."
fi

# --- permafrost (DeepSeek proxy for the claude-sk fish function) ----------
# Zero-dependency stdlib Python; cloned here, started on demand via
# `~/Projects/permafrost/cli/permafrost wrap` (see its README).
log::step "Cloning permafrost"
PERMAFROST_DIR="$HOME/Projects/permafrost"
if [[ -d "$PERMAFROST_DIR/.git" ]]; then
  log::ok "Already present at $PERMAFROST_DIR."
else
  mkdir -p "$(dirname "$PERMAFROST_DIR")"
  git clone --depth=1 https://github.com/jianzhichun/permafrost.git "$PERMAFROST_DIR"
  log::ok "Cloned permafrost."
fi

# --- dotfiles via chezmoi -------------------------------------------------
# Prompts ONCE for the DeepSeek API key (stored in machine-local
# ~/.config/chezmoi/chezmoi.toml, never committed). Applies every config file
# and runs the chrome-devtools MCP registration script.
log::step "Applying dotfiles with chezmoi (will prompt for the DeepSeek API key)"
chezmoi init "$DOTFILES_REPO"
if (( FORCE )); then
  chezmoi apply --force
else
  chezmoi apply
fi
log::ok "Dotfiles applied."

# --- register fish as a valid login shell --------------------------------
log::step "Registering fish as a login shell"
if ! grep -Fxq "$FISH_BIN" /etc/shells; then
  log::info "Appending $FISH_BIN to /etc/shells (sudo required)"
  echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null
fi
log::ok "/etc/shells contains $FISH_BIN"

# --- switch default shell -------------------------------------------------
log::step "Switching default shell to fish"
current_shell="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
if [[ "$current_shell" == "$FISH_BIN" ]]; then
  log::ok "Already using fish."
else
  log::info "Running: chsh -s $FISH_BIN  (enter your login password)"
  chsh -s "$FISH_BIN"
  log::ok "Default shell is now fish."
fi

# --- done -----------------------------------------------------------------
cat <<EOF

$(printf '\033[38;2;166;227;161m')━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(printf '\033[0m')
  Setup complete.

  Next steps:
    1. Quit Terminal.app, launch Ghostty (Spotlight: "Ghostty").
    2. Launch 'claude', then install the HUD plugin:
         /plugin marketplace add jarrodwatts/claude-hud
         /plugin install claude-hud
       (its config.json is already in place via chezmoi)
    3. For claude-sk (DeepSeek): start the proxy when needed —
         ~/Projects/permafrost/cli/permafrost wrap
       See ~/Projects/permafrost/README.md.

  Reminder: the DeepSeek key you entered must be a VALID, current key.

  To update later:
    cd $REPO_ROOT && git pull && ./post-install.sh   # tools
    chezmoi update                                    # dotfiles
$(printf '\033[38;2;166;227;161m')━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(printf '\033[0m')
EOF

# Try to open Ghostty automatically (best-effort)
if [[ -d "/Applications/Ghostty.app" ]]; then
  open -a Ghostty >/dev/null 2>&1 || true
fi
