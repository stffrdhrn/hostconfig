# Definitions for my PS1

case $TERM in
   xterm|terminator)
      PROMPT_COMMAND='echo -ne "\033]0;-{${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}}-"; echo -ne "\007"'
      ;;
esac

# colors, something is screwed up here
WB='\[\e[30;47m\]'
WR='\[\e[31;47m\]'
NC='\[\e[0m\]'
PS1=${WB}'< \u'${WR}'@'${WB}'\h \w >'${NC}' '
PS2=${WR}'>'${NC}

