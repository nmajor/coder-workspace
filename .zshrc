# Minimal, fast defaults
export ZDOTDIR="$HOME"
export HISTFILE="$HOME/.zsh_history"
export SAVEHIST=5000
export HISTSIZE=5000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY
setopt AUTO_CD
setopt CORRECT

# Prompt
# Starship prompt
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# asdf
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
fi
fpath=($HOME/.asdf/completions $fpath)
autoload -Uz compinit
compinit
if [ -f "$HOME/.asdf/completions/asdf.zsh" ]; then
  . "$HOME/.asdf/completions/asdf.zsh"
fi

# Set default directory to app folder (only if starting from home)
if [ "$PWD" = "$HOME" ]; then
    cd ~/app
fi

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias lg='git lg'
alias gundo='git reset --soft HEAD~1'

# Phoenix development aliases
alias phx="mix phx.server"
alias phxd="MIX_ENV=dev mix phx.server"
alias phxt="MIX_ENV=test mix test"
alias ecto="mix ecto"
alias iex="iex -S mix"

# Database shortcuts
alias db.create="mix ecto.create"
alias db.migrate="mix ecto.migrate"
alias db.reset="mix ecto.reset"
alias db.seed="mix ecto.seed"
