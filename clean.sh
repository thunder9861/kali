git clean -d -f ./config/includes.chroot/
lb clean noauto
rm -rf config/binary config/bootstrap config/chroot config/common config/source
rm -f binary.log prepare.log
