# .zshrc 2026
# Author: Charles Patel

# Deduplicate $PATH on every shell start
typeset -U PATH path

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Update zsh automatically
zstyle ':omz:update' mode auto      

# Command execution timestamp in the history command output
# Three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="mm/dd/yyyy"

plugins=(
    git
    zsh-autosuggestions
    zsh-completions
    zsh-history-substring-search
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# For a full list of active aliases, run `alias`.

# Aliases
alias zshconfig="code ~/.zshrc"
alias cd=" cd"
alias ..=" cd ..; ls"
alias ...=" cd ..; cd ..; ls"
alias ....=" cd ..; cd ..; cd ..; ls"
alias cd..=".."
alias cd...="..."
alias cd....="...."

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH=$PATH:"$HOME/.local/bin"

# Added by LM Studio CLI (lms)
export PATH=$PATH:"$HOME/.lmstudio/bin"

# GPG TTY (For git commit signing)
export GPG_TTY=$(tty)

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"

export PATH=$PATH:"$PYENV_ROOT/bin"

eval "$(pyenv init - zsh)"

# Pyenv Virtual Environment
eval "$(pyenv virtualenv-init -)"
