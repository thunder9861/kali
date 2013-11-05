# Source .bashrc
. ~/.bashrc

# Start X if on tty1
if [ "`tty`" == '/dev/tty1' ]
then
   startx
   
# Start Byobu if on tty2
elif [ "`tty`" == '/dev/tty2' ]
then
   _byobu_sourced=1 . /usr/bin/byobu-launch
fi
