# .zshrc 2026
# Author: Charles Patel

# Deduplicate $PATH on every shell start
typeset -U PATH path

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Update zsh automatically
zstyle ':omz:update' mode auto

## History (huge quality of life)
HISTSIZE=100000
SAVEHIST=100000
# Sync history across sessions
setopt SHARE_HISTORY        
setopt HIST_IGNORE_ALL_DUPS
# Commands starting with space aren't saved
setopt HIST_IGNORE_SPACE    
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

# For a full list of active aliases, run `alias`.

## Aliases

# Usual
alias zshconfig="code ~/.zshrc"
alias reload="source ~/.zshrc"
alias path='echo $PATH | tr ":" "\n"'   # readable PATH
alias cd=" cd"
alias ..=" cd ..; ls"
alias ...=" cd ..; cd ..; ls"
alias ....=" cd ..; cd ..; cd ..; ls"
alias cd..=".."
alias cd...="..."
alias cd....="...."

# Git
alias gs="git status"
alias gd="git diff"
alias gl="git log"
alias gc="git checkout ."
alias gcm="git checkout main"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

export PATH=$PATH:"$HOME/.local/bin"

# Added by LM Studio CLI (lms)
export PATH=$PATH:"$HOME/.lmstudio/bin"

# PyCharm
export PATH=$PATH:"/Applications/PyCharm.app/Contents/MacOS"

# GPG TTY (For git commit signing)
export GPG_TTY=$(tty)

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"

export PATH=$PATH:"$PYENV_ROOT/bin"

eval "$(pyenv init - zsh)"

# Pyenv Virtual Environment
eval "$(pyenv virtualenv-init -)"
