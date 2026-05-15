# ---------------------------------------------------------------------------
# mac-bootstrap fish config
# ---------------------------------------------------------------------------

set -g fish_greeting

# ---- Homebrew (arm64 or x86_64) ----
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -x /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
end

# ---- Editor ----
set -gx EDITOR nvim

# ---- iCloud Drive ----
set -gx icd "$HOME/Library/Mobile Documents/com~apple~CloudDocs"

# ---- Python (pyenv) ----
status is-interactive; and command -v pyenv >/dev/null; and pyenv init - fish | source

# ---- Bun ----
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path $BUN_INSTALL/bin

# ---- Ripgrep ----
set -gx RIPGREP_CONFIG_PATH ~/.config/ripgrep/config

# ---- fzf (Catppuccin Mocha) ----
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git"
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#313244,label:#cdd6f4"
command -v fzf >/dev/null; and fzf --fish | source

# ---- Aliases ----
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --icons --group-directories-first --git"
alias la="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --icons --level=2"
alias cat="bat"

# ---- Abbreviations ----
abbr -a lg lazygit
abbr -a v nvim
abbr -a g git
abbr -a gs "git status -sb"
abbr -a gp "git push"
abbr -a gl "git pull"
abbr -a gd "git diff"
abbr -a gc "git commit"
abbr -a y yazi

# ---- zoxide (smart cd) ----
command -v zoxide >/dev/null; and zoxide init fish | source

# ---- Starship prompt ----
command -v starship >/dev/null; and starship init fish | source
