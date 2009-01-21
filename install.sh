#!/bin/sh

[ $# -ne 1 ] && echo "install.sh <root install path>" && exit 1
mkdir -p ${1}/sbin
mkdir -p ${1}/lib/initcpio
mkdir -p ${1}/etc

sed -e 's|CONFIG="mkinitcpio.conf"|CONFIG="/etc/mkinitcpio.conf"|g' \
    -e 's|FUNCTIONS="functions"|FUNCTIONS="/lib/initcpio/functions"|g' \
    -e 's|HOOKDIR="hooks"|HOOKDIR="/lib/initcpio/hooks"|g' \
    -e 's|INSTDIR="install"|INSTDIR="/lib/initcpio/install"|g' \
    -e 's|PRESETDIR="mkinitcpio.d"|PRESETDIR="/etc/mkinitcpio.d"|g' \
    < mkinitcpio > ${1}/sbin/mkinitcpio
chmod 755 ${1}/sbin/mkinitcpio

install -D -m644 mkinitcpio.conf ${1}/etc/mkinitcpio.conf
install -D -m755 init ${1}/lib/initcpio/init
install -D -m644 functions ${1}/lib/initcpio/functions
cp -r hooks/ ${1}/lib/initcpio/
cp -r install/ ${1}/lib/initcpio/
cp -r mkinitcpio.d/ ${1}/etc/mkinitcpio.d

#a2x -d manpage -f manpage mkinitcpio.5.txt
gzip -c --best mkinitcpio.5 > mkinitcpio.5.gz
install -D -m644 mkinitcpio.5.gz ${1}/usr/man/man5/mkinitcpio.5.gz
