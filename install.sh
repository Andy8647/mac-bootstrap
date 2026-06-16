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

  --force   pass --force to 'chezmoi apply' (overwrite configs without prompting)
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

# Config files are managed by chezmoi (handed off in post-install.sh), which
# does its own conflict handling — no symlink preflight needed here. The
# --force flag is passed through to `chezmoi apply --force`.

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
  # Note: `bash -c "$(curl ...)"` swallows curl failures because the failed
  # substitution just becomes `bash -c ""` which exits 0. Fetch the installer
  # to a temp file first so we can fail loudly on network errors.
  brew_installer="$(mktemp -t brew-install)"
  trap 'rm -f "$brew_installer"' EXIT
  if ! curl -fsSL --retry 3 --retry-delay 2 \
       https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh \
       -o "$brew_installer"; then
    die "Failed to download Homebrew installer. Check your network and re-run the bootstrap."
  fi
  /bin/bash "$brew_installer"
fi
[[ -x "$BREW_PREFIX/bin/brew" ]] \
  || die "Homebrew binary not found at $BREW_PREFIX/bin/brew after install. Re-run the bootstrap."
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
# Note: avoid `"${arr[@]}"` for an empty array — bash 3.2 (macOS /bin/bash)
# treats it as unbound under `set -u`. Branch instead.
step "Running post-install"
if (( FORCE )); then
  exec bash "$REPO_ROOT/post-install.sh" --force
else
  exec bash "$REPO_ROOT/post-install.sh"
fi
