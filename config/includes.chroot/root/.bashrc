# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Add ~/bin to the path
if [[ ":$PATH:" != *":/root/bin:"* ]]; then
   export PATH=$PATH:/root/bin
fi

# Solarized Colors
if [ "$TERM" = "linux" ]; then
    echo -en "\e]P0073642" # black
    echo -en "\e]P1dc322f" # red
    echo -en "\e]P2859900" # green
    echo -en "\e]P3b58900" # yellow
    echo -en "\e]P4268bd2" # blue
    echo -en "\e]P5d33682" # magenta
    echo -en "\e]P62aa198" # cyan
    echo -en "\e]P7eee8d5" # white
    echo -en "\e]P8002b36" # brblack
    echo -en "\e]P9cb4b16" # brred
    echo -en "\e]PA586e75" # brgreen
    echo -en "\e]PB657b83" # bryellow
    echo -en "\e]PC839496" # brblue
    echo -en "\e]PD6c71c4" # brmagenta
    echo -en "\e]PE93a1a1" # brcyan
    echo -en "\e]PFfdf6e3" # brwhite
    clear
fi

# Swap Caps Lock and Escape
echo keycode 58 = Escape | loadkeys -
echo keycode 1 = Caps_Lock | loadkeys -

# If not running interactively, don't do anything
case $- in
   *i*) ;;
     *) return;;
esac

# Speedup Hack
# http://www.webupd8.org/2010/11/alternative-to-200-lines-kernel-patch.html
mkdir -p -m 0700 /dev/cgroup/cpu/user/$$ > /dev/null 2>&1
echo $$ > /dev/cgroup/cpu/user/$$/tasks
echo "1" > /dev/cgroup/cpu/user/$$/notify_on_release

# Don't put duplicate lines in the history.
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Shell options
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar
set -o vi

# Convert integer seconds to Ddays,HH:MM:SS
# http://stackoverflow.com/questions/1862510/how-can-the-last-commands-wall-time-be-put-in-the-bash-prompt
seconds2days() 
{ 
  printf "%ddays,%02d:%02d:%02d" $(((($1/60)/60)/24)) \
  $(((($1/60)/60)%24)) $((($1/60)%60)) $(($1%60)) |
  sed 's/^1days/1day/;s/^0days,\(00:\)*//;s/^0//' ; 
}
trap 'SECONDS=0' DEBUG

# Set prompts
PS1='\[\033[G\]\n# ---------------------------------------------------------- [\D{%m.%d.%y %H:%M:%S}]\r# => $? ($(seconds2days $SECONDS)s) \n# \u@\h:\w\n# \# >> '
PS2='# > '
PS3='# ?> '
PS4='# $LINENO >'

# If this is an xterm set the title
case "$TERM" in
   xterm*)
      PS1="\[\033]0;\u@\h:\w\007\]$PS1"
      ;;
   *)
      ;;
esac

# Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
   . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
   . /etc/bash_completion
fi

# Enable color support of ls
if [ -x /usr/bin/dircolors ]; then
   test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


# Alias definitions.
if [ -f ~/.bash_aliases ]; then
   . ~/.bash_aliases
fi

