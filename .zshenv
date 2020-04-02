# Aliases
# Temporal remove of Ninja usage (-G Ninja -DCMAKE_VERBOSE_MAKEFILE=ON), because doesn't support the variable CMAKE_BINARY_DIR.
alias cmake='cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_FLAGS=-fdebug-prefix-map=\${CMAKE_BINARY_DIR}=.'
alias ninja='ninja_exec() { ninja $*; if [ -f compile_commands.json ]; then cp compile_commands.json ../..; fi }; ninja_exec'

# Not necessary because colocon python app.
#alias colcon='colcon_exec() { \
#    if [ "$#" -eq 0 ]; then \
#        test -e colcon_command.sh && sh colcon_command.sh; \
#    else; \
#        echo "$*" | grep -qP "(^|\s)\Kcolcon(\s)*build(?=\s|$)"; \
#        if [ "$?" -eq 0 ]; then echo "colcon $*" > colcon_command.sh; fi; \
#        colcon $*; \
#    fi; \
#    jq -s add $(find . -iname compile_commands.json -print0 | grep -z . | xargs -0; test $pipestatus[2] -eq 0) > compile_commands.json.tmp && \
#    cp compile_commands.json.tmp ../../compile_commands.json }; colcon_exec'

alias :q='exit'
alias gpull='git pull --ff-only origin $(git_current_branch)'

# CCache
emulate -R bash -c 'source ~/.local/bin/tmpfs-ccache-user.sh'

# FZF
# Export directory where vim's plugin dein install fzf.
export FZF_BASE="${XDG_CACHE_HOME:=$HOME/.cache}/dein/repos/github.com/junegunn/fzf"
export FZF_DEFAULT_COMMAND='ag -g ""'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# GCC_COLORS
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# RIPGREP configuration file
export RIPGREP_CONFIG_PATH=$HOME/.config/ripgrep/config

# Make
NUMCPUS=`grep -c '^processor' /proc/cpuinfo`
NUMCPUS_JOBS=$(( $NUMCPUS - 1))
NUMCPUS_LOAD=$(( $NUMCPUS - 2)).8
export MAKEFLAGS="-j${NUMCPUS_JOBS} -l${NUMCPUS_LOAD}"
  # Variable used in CMake to pass through other project the MAKEFLAGS
export CMAKE_MAKEFLAGS=$MAKEFLAGS
