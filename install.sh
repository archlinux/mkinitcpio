#!/bin/sh

[ $# -ne 1 ] && echo "install.sh <root install path>" && exit 1
mkdir -p ${1}/sbin
mkdir -p ${1}/lib/initcpio

sed -e 's|CONFIG="mkinitcpio.conf"|CONFIG="/etc/mkinitcpio.conf"|g' \
    -e 's|FUNCTIONS="functions"|FUNCTIONS="/lib/initcpio/functions"|g' \
    -e 's|HOOKDIR="hooks"|HOOKDIR="/lib/initcpio/hooks"|g' \
    -e 's|INSTDIR="install"|INSTDIR="/lib/initcpio/install"|g' \
    < mkinitcpio > ${1}/sbin/mkinitcpio
chmod 755 ${1}/sbin/mkinitcpio

install -D -m644 mkinitcpio.conf ${1}/etc/mkinitcpio.conf
install -D -m755 init ${1}/lib/initcpio/init
install -D -m644 functions ${1}/lib/initcpio/functions
cp -r hooks/ ${1}/lib/initcpio/
cp -r install/ ${1}/lib/initcpio/

# install subs tool to solve IFS issues
cd subs
make
install -D -m755 subs ${1}/usr/lib/klibc/bin/subs
