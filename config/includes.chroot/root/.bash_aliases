# Colors
alias diff='colordiff'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto -E'
alias ls='ls --color=auto -h'

# Remappings
alias df='df -h'
alias du='du -ch'
alias less='less -XFNRMe'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias cgdb='cgdb -- --nx'

# Additional
alias ack='ack-grep -i -u'
alias bd='cd -'
alias h='history'

# Functions
mcd()
{
   mkdir -p $1 && cd $1
}

up()
{
   num=${1:-1}
   for((i=1; i <= num; i++))
   do
      cd ..
   done
}

