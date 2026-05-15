#!/usr/bin/env bash
#
# Runs after install.sh has bootstrapped Homebrew and cloned the repo.
# Installs the Brewfile, symlinks configs, and switches the login shell to fish.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/log.sh
source "$REPO_ROOT/lib/log.sh"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

command -v brew >/dev/null || log::die "Homebrew missing — run install.sh first."

# --- brew bundle ----------------------------------------------------------
log::step "Installing packages from Brewfile"
brew bundle --file="$REPO_ROOT/Brewfile"
log::ok "Brew bundle complete."

BREW_PREFIX="$(brew --prefix)"
FISH_BIN="$BREW_PREFIX/bin/fish"

# --- symlink configs ------------------------------------------------------
log::step "Linking configs into ~/.config"
link_config() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    if (( FORCE )); then
      local ts backup
      ts="$(date +%Y%m%d-%H%M%S)"
      backup="${dest}.bak-${ts}"
      mv "$dest" "$backup"
      log::warn "Moved $dest -> $backup"
    else
      log::die "$dest exists and is not a symlink. Re-run with --force."
    fi
  fi
  ln -sfn "$src" "$dest"
  log::ok "linked $(basename "$dest")"
}

link_config "$REPO_ROOT/configs/fish/config.fish"                    "$HOME/.config/fish/config.fish"
link_config "$REPO_ROOT/configs/fish/conf.d/catppuccin_mocha.fish"   "$HOME/.config/fish/conf.d/catppuccin_mocha.fish"
link_config "$REPO_ROOT/configs/ghostty/config"                      "$HOME/.config/ghostty/config"
link_config "$REPO_ROOT/configs/starship.toml"                       "$HOME/.config/starship.toml"

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
    1. Quit Terminal.app.
    2. Launch Ghostty  (Spotlight: "Ghostty")
    3. Enjoy your new shell.

  To update later:
    cd $REPO_ROOT && git pull && ./post-install.sh
$(printf '\033[38;2;166;227;161m')━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(printf '\033[0m')
EOF

# Try to open Ghostty automatically (best-effort)
if [[ -d "/Applications/Ghostty.app" ]]; then
  open -a Ghostty >/dev/null 2>&1 || true
fi
