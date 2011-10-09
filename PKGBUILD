pkgname=mkinitcpio-git
pkgver=$(make version)
pkgrel=1
pkgdesc="Modular initramfs image creation utility"
arch=(any)
url="http://www.archlinux.org/"
license=('GPL')
groups=('base')
conflicts=('mkinitcpio')
provides=("mkinitcpio=$pkgver")
depends=('mkinitcpio-busybox>=1.16.1-2' 'module-init-tools' 'util-linux>=2.19' 'libarchive' 'coreutils'
         'bash' 'findutils' 'sed' 'grep' 'filesystem>=2011.10-1' 'udev>=171-2' 'file' 'gzip')
makedepends=('asciidoc' 'git')
optdepends=('xz: Use lzma or xz compression for the initramfs image'
            'bzip2: Use bzip2 compression for the initramfs image'
            'lzop: Use lzo compression for the initramfs image'
            'mkinitcpio-nfs-utils: Support for root filesystem on NFS')
replaces=('mkinitrd' 'mkinitramfs' 'klibc' 'klibc-extras' 'klibc-kbd'
          'klibc-module-init-tools' 'klibc-udev')
backup=(etc/mkinitcpio.conf)

build() {
  make -C ..
}

package() {
  make -C .. DESTDIR="$pkgdir" install
}
