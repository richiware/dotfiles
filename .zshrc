# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="agnoster"
#ZSH_THEME="richiware"
#ZSH_THEME="powerlevel10k/powerlevel10k"
eval "$(starship init zsh)"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment following line if you want to  shown in the command execution time stamp
# in the history command output. The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|
# yyyy-mm-dd
# HIST_STAMPS="mm/dd/yyyy"

# Autostart tmux
ZSH_TMUX_AUTOSTART=true

# Location of my custom ZSH folder
ZSH_CUSTOM=~/.config/zsh/custom


# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
    git
    gitignore
    git-open
    taskwarrior
    thefuck
    vim-interaction
    notify
    tmux
    yadm-zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

# User configuration

path+=($HOME'/.local/bin')
path+=('/usr/local/bin')
path+=('/var/lib/snapd/bin')
export PATH
# export MANPATH="/usr/local/man:$MANPATH"

# # Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# RICHI configuration

# Sustitute oh-my-zsh's sudo alias for mine.
alias _='sudo -E'

ZVM_VI_EDITOR=$EDITOR

# 256 color term
if [[ "$TERM" == xterm* ]]; then
    export TERM=xterm-256color
fi

# GNU Colors
[ -f ~/.dircolors ] && eval $(dircolors ~/.dircolors)
export ZLSCOLORS="${LS_COLORS}"

# enable autocompletion for special directories
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'

# Get next line in local history
function up-line-or-local-history()
{
    zle set-local-history 1
    zle up-line-or-history
    zle set-local-history 0
}
zle -N up-line-or-local-history

# Get next line in local history
function down-line-or-local-history()
{
    zle set-local-history 1
    zle down-line-or-history
    zle set-local-history 0
}
zle -N down-line-or-local-history

# Update prompt (date) when execute a command
function _reset-prompt-and-accept-line {
  zle reset-prompt
  zle .accept-line     # Note the . meaning the built-in accept-line.
}
zle -N accept-line _reset-prompt-and-accept-line

# Special function to search text and show results using FZF
function sg()
{
    search_prg=("rg" "--vimgrep" "--color=always")
    inside_git_repo="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    directory="."

    if [ "$inside_git_repo" ]; then
        search_prg=("git" "grep" "-n" "-i" "--column" "--color=always")
    fi
    if [ "$2" ]; then
        directory=$2
    fi
    grep_rv=`$search_prg "$1" "$directory" | $(__fzfcmd) \
        --reverse \
        --ansi \
        --preview 'file=$(echo {} | cut -f 1 -d :) line=$(echo {} | cut -f 2 -d :); fzf-preview "$file" "$line"'
    `
    if [ "$grep_rv" ]; then
        echo $(awk '{split($0,a,":"); print "nvim",a[1],"-c","\"call cursor(\""a[2]","a[3]"\")\""}' <<< ${grep_rv}) | bash
    fi
}

function rsg()
{
    directory="."

    if [ "$2" ]; then
        directory=$2
    fi
    grep_rv=`rg --vimgrep --color=always "$1" "$directory" | $(__fzfcmd) \
        --reverse \
        --ansi \
        --preview 'file=$(echo {} | cut -f 1 -d :) line=$(echo {} | cut -f 2 -d :); fzf-preview "$file" "$line"'
    `
    if [ "$grep_rv" ]; then
        echo $(awk '{split($0,a,":"); print "nvim",a[1],"-c","\"call cursor(\""a[2]","a[3]"\")\""}' <<< ${grep_rv}) | bash
    fi
}

function show-calendar()
{
    echo "\nEntering calendars..."
    khal calendar
    task calendar
    zle reset-prompt
}
zle -N show-calendar

# Git-foresta aliases
function gifo() { git-foresta --style=10 "$@" | less -RSX }
function gifa() { git-foresta --all --style=10 "$@" | less -RSX }
compdef _git gifo=git-log
compdef _git gifa=git-log

#{{{ FZF
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh

__fzf_preview()
{
    LBUFFER="${LBUFFER}$(eval "${FZF_CTRL_T_COMMAND}" | \
        izer iconize -f=nerd -c | \
        FZF_DEFAULT_OPTS="--reverse $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" $(__fzfcmd) | \
        izer deiconize
        )"
    local ret=$?
    zle reset-prompt
    return $ret
}
zle -N __fzf_preview
#}}}

#{{{ Key Binding
# Alternative to ESC to switch to normal vi mode.
ZVM_VI_INSERT_ESCAPE_BINDKEY=jj # zsh-vi-mode
function my_key_bindings()
{
    # History search keys
    zvm_bindkey viins '^R' fzf-history-widget # zsh-vi-mode
    zvm_bindkey vicmd '^R' fzf-history-widget # zsh-vi-mode
    zvm_bindkey vicmd '/' fzf-history-widget # zsh-vi-mode
    bindkey '^H' vi-backward-char
    bindkey '^K' up-line-or-history
    bindkey '^J' down-line-or-history
    bindkey '^L' vi-forward-char
    bindkey '^P' up-history
    bindkey '^N' down-history
    bindkey "^?" backward-delete-char
    bindkey "^q" push-line-or-edit
    # Up arrow
    bindkey "^[OA" up-line-or-local-history
    # Down arrow
    bindkey "^[OB" down-line-or-local-history

    # Esc + Esc for run fuck command
    bindkey "\e\e" fuck-command-line

    # , + c for showing a calendar using khal
    zvm_bindkey vicmd ',c' show-calendar # zsh-vi-mode

    zvm_bindkey viins "^t" __fzf_preview
    zvm_bindkey viins '\et' fzf-file-widget
}
precmd_functions+=(my_key_bindings)
#}}}

# ZSH notify
zstyle ':notify:*' error-icon "/home/ricardo/.signs/virus.png"
zstyle ':notify:*' error-title "Command failed"
zstyle ':notify:*' success-icon "/home/ricardo/.signs/checked.png"
zstyle ':notify:*' success-title "Command success"
zstyle ':notify:*' blacklist-regex 'colcon'


### Used with tmux to initialize my personal environment
function run_my_apps()
{
    if [[ -n ${__tmux_my_env__} ]]; then
        zsh -c ${__tmux_my_env__}
    fi
}
precmd_functions+=(run_my_apps)
