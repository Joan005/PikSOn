# historial

HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS

# comodidad

setopt interactivecomments
unsetopt nomatch

# autocompletado

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# teclas inicio, fin y supr


# alias

alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias t='tree -a -I ".git"'

# prompt

eval "$(starship init zsh)"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
