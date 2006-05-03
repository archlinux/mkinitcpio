# $Id: PKGBUILD,v 1.63 2005/12/26 09:54:29 tpowa Exp $
# Maintainer : Tobias Powalowski <tpowa@archlinux.org>, Aaron Griffin <aaron@archlinux.org>

pkgname=mkinitcpio
pkgver=0.1
pkgrel=1
pkgdesc="Program to create initramfs images for archlinux"
url="http://www.archlinux.org/"
depends=('klibc' 'klibc-extras' 'klibc-udev' 'gen-init-cpio')
source=(mkinitcpio.tar.bz2)

build()
{
  cd $startdir/src/
  # fixing paths in mkinitcpio
  sed -i -e 's|FILELIST=".tmpfilelist"|FILELIST="/tmp/.tmpfilelist"|g' mkinitcpio
  sed -i -e 's|CONFIG="mkinitcpio.conf"|CONFIG="/etc/mkinitcpio.conf"|g' mkinitcpio
  sed -i -e 's|FUNCTIONS="functions"|FUNCTIONS="/lib/initcpio/functions"|g' mkinitcpio
  sed -i -e 's|HOOKDIR="hooks"|HOOKDIR="/lib/initcpio/hooks"|g' mkinitcpio
  sed -i -e 's|INSTDIR="install"|INSTDIR="/lib/initcpio/install"|g' mkinitcpio
  install -D -m644 mkinitcpio.conf $startdir/pkg/etc/mkinitcpio.conf
  install -D -m755 mkinitcpio $startdir/pkg/sbin/mkinitcpio
  install -D -m755 init $startdir/pkg/lib/initcpio/init
  install -D -m644 functions $startdir/pkg/lib/initcpio/functions
  cp -r hooks/ $startdir/pkg/lib/initcpio/
  cp -r install/ $startdir/pkg/lib/initcpio/
}
