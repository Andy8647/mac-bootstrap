#!/usr/bin/env bash
#
# Mac bootstrap: one-shot terminal environment installer.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/Andy8647/mac-bootstrap/main/install.sh | bash -s -- --force
#
set -euo pipefail

REPO_URL="${MAC_BOOTSTRAP_REPO:-https://github.com/Andy8647/mac-bootstrap.git}"
INSTALL_DIR="${MAC_BOOTSTRAP_DIR:-$HOME/.local/share/mac-bootstrap}"
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    --help|-h)
      cat <<EOF
Mac bootstrap installer

  --force   overwrite existing ~/.config/{fish,ghostty} (backed up first)
  --help    show this help
EOF
      exit 0
      ;;
  esac
done

# --- locate repo root -----------------------------------------------------
# If running via curl|bash, BASH_SOURCE is empty/stdin -> clone into INSTALL_DIR.
# If running as ./install.sh, use the script's own directory.
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  REPO_ROOT=""
fi

# --- bootstrap logger -----------------------------------------------------
# When piped we can't source lib/log.sh yet; inline a tiny version.
_c_mauve=$'\033[38;2;203;166;247m'
_c_red=$'\033[38;2;243;139;168m'
_c_green=$'\033[38;2;166;227;161m'
_c_yellow=$'\033[38;2;249;226;175m'
_c_reset=$'\033[0m'
step() { printf '\n%s▸ %s%s\n' "$_c_mauve" "$*" "$_c_reset"; }
ok()   { printf '%s✓ %s%s\n' "$_c_green" "$*" "$_c_reset"; }
warn() { printf '%s! %s%s\n' "$_c_yellow" "$*" "$_c_reset" >&2; }
die()  { printf '%s✗ %s%s\n' "$_c_red" "$*" "$_c_reset" >&2; exit 1; }

# --- preflight ------------------------------------------------------------
[[ "$(uname)" == "Darwin" ]] || die "This installer only supports macOS."

ARCH="$(uname -m)"
case "$ARCH" in
  arm64)  BREW_PREFIX="/opt/homebrew" ;;
  x86_64) BREW_PREFIX="/usr/local" ;;
  *)      die "Unsupported architecture: $ARCH" ;;
esac

step "Checking for existing configs"
conflicts=()
for p in "$HOME/.config/fish/config.fish" "$HOME/.config/ghostty/config" "$HOME/.config/starship.toml"; do
  [[ -e "$p" && ! -L "$p" ]] && conflicts+=("$p")
done
if (( ${#conflicts[@]} > 0 )); then
  if (( FORCE )); then
    ts="$(date +%Y%m%d-%H%M%S)"
    backup="$HOME/.config/backup-$ts"
    mkdir -p "$backup"
    for p in "${conflicts[@]}"; do
      rel="${p#$HOME/.config/}"
      mkdir -p "$backup/$(dirname "$rel")"
      mv "$p" "$backup/$rel"
    done
    ok "Backed up existing configs to $backup"
  else
    warn "Found existing configs:"
    for p in "${conflicts[@]}"; do printf '    %s\n' "$p" >&2; done
    die "Re-run with --force to back them up and continue."
  fi
else
  ok "No conflicting configs."
fi

# --- Xcode Command Line Tools --------------------------------------------
step "Installing Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "Already installed."
else
  xcode-select --install || true
  warn "A dialog may appear. Waiting for installation to complete..."
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
  ok "Xcode Command Line Tools installed."
fi

# --- Homebrew -------------------------------------------------------------
step "Installing Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "Already installed at $(command -v brew)."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$("$BREW_PREFIX/bin/brew" shellenv)"

# --- fetch repo -----------------------------------------------------------
if [[ -z "$REPO_ROOT" ]]; then
  step "Fetching mac-bootstrap repo"
  if [[ -d "$INSTALL_DIR/.git" ]]; then
    git -C "$INSTALL_DIR" pull --ff-only
  else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  fi
  REPO_ROOT="$INSTALL_DIR"
fi
ok "Repo at $REPO_ROOT"

# --- hand off to post-install --------------------------------------------
step "Running post-install"
post_args=()
(( FORCE )) && post_args+=(--force)
exec bash "$REPO_ROOT/post-install.sh" "${post_args[@]}"
