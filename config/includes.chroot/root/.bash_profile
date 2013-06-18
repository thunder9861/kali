
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

# Autostart Byobu on tty2
# [[ `tty` == '/dev/tty2' ]] && `echo $- | grep -qs i` && byobu-launcher && exit 0

