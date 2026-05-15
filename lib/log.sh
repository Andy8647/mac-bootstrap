# shellcheck shell=bash
# Colored logging helpers. Source this file, do not execute.

if [[ -t 1 ]]; then
  _c_reset=$'\033[0m'
  _c_dim=$'\033[2m'
  _c_red=$'\033[38;2;243;139;168m'
  _c_peach=$'\033[38;2;250;179;135m'
  _c_yellow=$'\033[38;2;249;226;175m'
  _c_green=$'\033[38;2;166;227;161m'
  _c_sapphire=$'\033[38;2;116;199;236m'
  _c_mauve=$'\033[38;2;203;166;247m'
else
  _c_reset='' _c_dim='' _c_red='' _c_peach='' _c_yellow='' _c_green='' _c_sapphire='' _c_mauve=''
fi

log::step()  { printf '\n%s▸ %s%s\n'       "$_c_mauve"    "$*" "$_c_reset"; }
log::info()  { printf '%s  %s%s\n'         "$_c_sapphire" "$*" "$_c_reset"; }
log::ok()    { printf '%s✓ %s%s\n'         "$_c_green"    "$*" "$_c_reset"; }
log::warn()  { printf '%s! %s%s\n'         "$_c_yellow"   "$*" "$_c_reset" >&2; }
log::err()   { printf '%s✗ %s%s\n'         "$_c_red"      "$*" "$_c_reset" >&2; }
log::dim()   { printf '%s  %s%s\n'         "$_c_dim"      "$*" "$_c_reset"; }

log::die()   { log::err "$*"; exit 1; }
