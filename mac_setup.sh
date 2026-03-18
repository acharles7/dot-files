#!/usr/bin/env bash
# =============================================================================
# mac_setup.sh — New Mac bootstrap script
#
# Usage:
#   bash mac_setup.sh           # Full install
#   bash mac_setup.sh --dry-run # Preview what's installed / missing (no changes)
# =============================================================================

set -euo pipefail

# ── Dry-run flag ──────────────────────────────────────────────────────────────
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=true
fi

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
step()    { echo -e "\n${BLUE}${BOLD}▶ $1${NC}"; }
ok()      { echo -e "  ${GREEN}✓${NC}  $1"; }
missing() { echo -e "  ${RED}✗${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
info()    { echo -e "  ${CYAN}→${NC}  $1"; }

# In dry-run mode: print what WOULD happen instead of doing it
run() {
  if $DRY_RUN; then
    echo -e "  ${CYAN}[dry-run]${NC} $*"
  else
    "$@"
  fi
}

# =============================================================================
# DRY-RUN: STATUS CHECK (prints a full report, then exits)
# =============================================================================
if $DRY_RUN; then
  echo -e "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}${BOLD}   Mac Setup — Dry Run (nothing will change)${NC}"
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  MISSING_COUNT=0
  INSTALLED_COUNT=0

  check() {
    local label="$1"
    local check_cmd="$2"
    if eval "$check_cmd" &>/dev/null 2>&1; then
      ok "$label"
      (( INSTALLED_COUNT++ )) || true
    else
      missing "$label"
      (( MISSING_COUNT++ )) || true
    fi
  }

  # ── Core tools ──────────────────────────────────────────────────────────────
  step "Package managers"
  check "Homebrew"         "command -v brew"
  check "Oh My Zsh"        "[[ -d \$HOME/.oh-my-zsh ]]"

  # ── Zsh plugins ─────────────────────────────────────────────────────────────
  step "Zsh plugins"
  ZSH_CUSTOM_CHECK="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
  check "zsh-autosuggestions"          "[[ -d $ZSH_CUSTOM_CHECK/plugins/zsh-autosuggestions ]]"
  check "zsh-syntax-highlighting"      "[[ -d $ZSH_CUSTOM_CHECK/plugins/zsh-syntax-highlighting ]]"
  check "zsh-history-substring-search" "[[ -d $ZSH_CUSTOM_CHECK/plugins/zsh-history-substring-search ]]"
  check "zsh-completions"              "[[ -d $ZSH_CUSTOM_CHECK/plugins/zsh-completions ]]"

  # ── Git ─────────────────────────────────────────────────────────────────────
  step "Git config"
  check "git user.name set"    "git config --global user.name | grep -q ."
  check "git user.email set"   "git config --global user.email | grep -q ."
  check "gpg commit signing"   "git config --global commit.gpgsign | grep -q true"
  check "gpg tag signing"      "git config --global tag.gpgSign | grep -q true"
  check "default branch=main"  "git config --global init.defaultBranch | grep -q main"
  check "alias: lg"            "git config --global alias.lg | grep -q ."
  check "alias: undo"          "git config --global alias.undo | grep -q ."

  # ── GPG ─────────────────────────────────────────────────────────────────────
  step "GPG"
  check "gnupg installed"       "command -v gpg"
  check "GPG secret key exists" "gpg --list-secret-keys | grep -q sec"
  check "GPG_TTY in .zshrc"     "grep -q GPG_TTY \$HOME/.zshrc"

  # ── Python ──────────────────────────────────────────────────────────────────
  step "Python"
  check "pyenv"              "command -v pyenv || [[ -x \$HOME/.pyenv/bin/pyenv ]]"
  check "pyenv-virtualenv"   "[[ -d \$HOME/.pyenv/plugins/pyenv-virtualenv ]] || brew list pyenv-virtualenv &>/dev/null"
  # Check via filesystem directly — avoids needing pyenv shell init in this subshell
  check "Python 3.12.13"     "[[ -d \$HOME/.pyenv/versions/3.12.13 ]]"
  check "pyenv in .zshrc"    "grep -q 'pyenv init' \$HOME/.zshrc"

  # ── Productivity tools ───────────────────────────────────────────────────────
  step "Productivity tools"
  # Use brew list as fallback — tools may be installed but not on PATH yet (pre-.zshrc reload)
  _brew_or_cmd() {
    local cmd="$1" pkg="${2:-$1}"
    command -v "$cmd" &>/dev/null || brew list "$pkg" &>/dev/null
  }
  for tool in fzf ripgrep bat eza fd jq tldr gh httpie; do
    # map brew package name to the actual command name for display
    case $tool in
      ripgrep) label="rg" ;;
      httpie)  label="http" ;;
      *)       label="$tool" ;;
    esac
    check "$label" "_brew_or_cmd $label $tool"
  done
  check "fzf shell integration" "[[ -f \$HOME/.fzf.zsh ]]"

  # ── Claude Code ─────────────────────────────────────────────────────────────
  step "Claude Code"
  check "claude CLI"                    "command -v claude"
  check "~/.local/bin in PATH (zshrc)"  "grep -q '.local/bin' \$HOME/.zshrc"

  # ── .zshrc ──────────────────────────────────────────────────────────────────
  step ".zshrc patches"
  check "Setup script block present" "grep -q 'Setup script additions' \$HOME/.zshrc"

  # ── Summary ─────────────────────────────────────────────────────────────────
  TOTAL=$((INSTALLED_COUNT + MISSING_COUNT))
  echo ""
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${GREEN}✓ Installed: $INSTALLED_COUNT / $TOTAL${NC}"
  if [[ $MISSING_COUNT -gt 0 ]]; then
    echo -e "  ${RED}✗ Missing:   $MISSING_COUNT / $TOTAL${NC}"
    echo ""
    echo -e "  Run ${BOLD}bash mac_setup.sh${NC} to install everything."
  else
    echo -e "  ${GREEN}${BOLD}All items installed — you're good to go!${NC}"
  fi
  echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  exit 0
fi

# =============================================================================
# FULL INSTALL MODE
# =============================================================================

echo -e "\n${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}   Mac Setup Script${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "Tip: run with --dry-run first to preview what's already installed."
echo ""

read -rp "Git name (e.g. 'John Doe'): " GIT_NAME
read -rp "Git email: " GIT_EMAIL
read -rp "Skip GPG signing setup? [y/N]: " SKIP_GPG
SKIP_GPG="${SKIP_GPG:-n}"

# =============================================================================
# 1. HOMEBREW
# =============================================================================
step "Homebrew"
if ! command -v brew &>/dev/null; then
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    run echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
  fi
  ok "Homebrew installed"
else
  ok "Homebrew already installed — skipping"
fi

run brew update

# =============================================================================
# 2. OH-MY-ZSH
# =============================================================================
step "Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  run RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed — skipping"
fi

# =============================================================================
# 3. ZSH PLUGINS
# =============================================================================
step "Zsh plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"

declare -A ZSH_PLUGINS=(
  ["zsh-completions"]="https://github.com/zsh-users/zsh-completions.git"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
  ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search.git"
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
)

for plugin in "${!ZSH_PLUGINS[@]}"; do
  plugin_dir="$ZSH_CUSTOM/plugins/$plugin"
  if [[ ! -d "$plugin_dir" ]]; then
    run git clone "${ZSH_PLUGINS[$plugin]}" "$plugin_dir"
    ok "Installed: $plugin"
  else
    ok "Already installed: $plugin — skipping"
  fi
done

run brew install zsh-completions

# =============================================================================
# 4. GIT CONFIG
# =============================================================================
step "Git config"
run git config --global user.name "$GIT_NAME"
run git config --global user.email "$GIT_EMAIL"
run git config --global init.defaultBranch main
run git config --global pull.rebase false
run git config --global core.autocrlf input
run git config --global alias.lg "log --oneline --graph --decorate --all"
run git config --global alias.st "status -sb"
run git config --global alias.undo "reset --soft HEAD~1"
ok "Git configured for $GIT_NAME <$GIT_EMAIL>"

# =============================================================================
# 5. GPG SIGNING
# =============================================================================
if [[ "$SKIP_GPG" =~ ^[Nn]$ ]]; then
  step "GPG commit signing"
  run brew install gnupg
  warn "You'll be prompted to create a GPG key. Use the same email as your Git config."
  run gpg --full-generate-key
  GPG_KEY=$(gpg --list-secret-keys --keyid-format=long | grep ^sec | head -1 | awk '{print $2}' | cut -d'/' -f2)
  run git config --global user.signingkey "$GPG_KEY"
  run git config --global commit.gpgsign true
  run git config --global tag.gpgSign true
  run git config --global --unset gpg.format 2>/dev/null || true
  echo ""
  echo "Add this GPG public key to GitHub → Settings → SSH and GPG keys:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  gpg --armor --export "$GPG_KEY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ok "GPG signing configured (key: $GPG_KEY)"
else
  warn "Skipping GPG setup"
fi

# =============================================================================
# 6. PYTHON (pyenv + pyenv-virtualenv)
# =============================================================================
step "Python"
run brew install pyenv pyenv-virtualenv

PYTHON_VERSION="3.12.13"
if ! pyenv versions 2>/dev/null | grep -q "$PYTHON_VERSION"; then
  run pyenv install "$PYTHON_VERSION"
  ok "Python $PYTHON_VERSION installed"
else
  ok "Python $PYTHON_VERSION already installed — skipping"
fi

run pyenv global "$PYTHON_VERSION"

# =============================================================================
# 7. PRODUCTIVITY TOOLS
# =============================================================================
step "Productivity tools"

BREW_TOOLS=(fzf ripgrep bat eza fd jq tldr gh httpie)
for tool in "${BREW_TOOLS[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    run brew install "$tool"
    ok "Installed: $tool"
  else
    ok "Already installed: $tool — skipping"
  fi
done

if [[ ! -f "$HOME/.fzf.zsh" ]]; then
  run "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
  ok "fzf shell integration installed"
else
  ok "fzf shell integration already present — skipping"
fi

# =============================================================================
# 8. CLAUDE CODE CLI
# =============================================================================
step "Claude Code"
if ! command -v claude &>/dev/null; then
  run curl -fsSL https://claude.ai/install.sh | bash
  ok "Claude Code installed"
else
  ok "Claude Code already installed — skipping"
fi

if ! grep -q '.local/bin' ~/.zshrc; then
  run echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
fi

# =============================================================================
# 9. .ZSHRC PATCHES
# =============================================================================
step ".zshrc patches"

ZSHRC_PATCH='
# ── Setup script additions ──────────────────────────────────────────────────

# GPG TTY (required for signed commits in terminal)
export GPG_TTY=$(tty)

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Oh My Zsh plugins (update the plugins=() line in your .zshrc to include these)
# plugins=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Better defaults using new tools
alias cat="bat --paging=never"
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias grep="rg"
alias find="fd"

# Git shortcuts
alias gs="git status -sb"
alias gp="git push"
alias gl="git lg"
alias gundo="git undo"

# Python
alias py="python3"
alias pip="pip3"
'

if ! grep -q 'Setup script additions' ~/.zshrc; then
  run echo "$ZSHRC_PATCH" >> ~/.zshrc
  ok ".zshrc patched"
else
  ok ".zshrc already patched — skipping"
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  ✓ Setup complete! Restart your terminal.${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Update plugins=() in your .zshrc to include the zsh-* plugins"
if [[ "$SKIP_GPG" =~ ^[Nn]$ ]]; then
  echo "  2. Add the GPG key printed above to GitHub"
fi
echo "  3. Run: exec \$SHELL"
