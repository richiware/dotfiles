# This theme was based on:
# Blinks (https://github.com/blinks) zsh theme
# Wild cherry theme: https://github.com/mashaal/wild-cherry
# Agnoster theme: https://github.com/agnoster/agnoster-zsh-theme

# This theme works with both the "dark" and "light" variants of the
# Solarized color schema.  Set the SOLARIZED_THEME variable to one of
# these two values to choose.  If you don't specify, we'll assume you're
# using the "dark" variant.
case ${SOLARIZED_THEME:-dark} in
    light) bkg=white;;
    *)     bkg=black;;
esac

ZSH_THEME_GIT_PROMPT_PREFIX=" [%{%B%F{blue}%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{%f%k%b%K{${bkg}}%B%F{green}%}]"
ZSH_THEME_GIT_PROMPT_DIRTY=" 💀"
ZSH_THEME_GIT_PROMPT_CLEAN=" 🌷"
ZSH_THEME_GIT_PROMPT_ADDED=" 💅"
ZSH_THEME_GIT_PROMPT_MODIFIED=" 🍄"
ZSH_THEME_GIT_PROMPT_DELETED=" 💥"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" 🎀"
ZSH_THEME_GIT_PROMPT_RENAMED=" 👉"
ZSH_THEME_GIT_PROMPT_UNMERGED=" 👊"
ZSH_THEME_GIT_PROMPT_AHEAD=" 👆"
ZSH_THEME_GIT_PROMPT_BEHIND=" 👇"
ZSH_THEME_GIT_PROMPT_DIVERGED=" 🙌"

# Check the UID
if [[ $UID -ne 0 ]]; then # normal user
  PR_USER='%B%F{green}%n'
  PR_PROMPT='%f➤ %f'
else # root
  PR_USER='%B%F{red}%n'
  PR_PROMPT='%F{red}➤ %f'
fi

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols

  symbols+="%(?..%{%F{red}%}✘ )"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙ "

  [[ -n "$symbols" ]] && echo "$symbols"
}

MODE_VI_INDICATOR="%{%B%F{red}%}╰─➤"
MODE_NO_INDICATOR="╰─➤"

function vi_mode_prompt_str() {
    local mode="${VIM_MODE_KEYMAP-$KEYMAP}"
    if [[ "$mode" == "" ]]; then
        echo "$MODE_NO_INDICATOR"
    else
        echo "${${mode/vicmd/$MODE_VI_INDICATOR}/(main|viins)/$MODE_NO_INDICATOR}"
    fi
}

PROMPT='%{%f%k%b%}
%{%K{${bkg}}%}$(prompt_status)$PR_USER%{%B%F{blue}%}@%{%B%F{cyan}%}%m%{%B%F{green}%} %{%b%F{yellow}%K{${bkg}}%}${PWD/#$HOME/~}%{%B%F{green}%}$(git_prompt_info)%E%{%f%k%b%}
$(vi_mode_prompt_str)%{%f%k%b%} '

RPROMPT='%{%B%F{cyan}%}[%*]'
