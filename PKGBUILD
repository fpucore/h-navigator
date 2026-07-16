# Maintainer: Chris McGimpsey-Jones <chrisjones.unixmen@gmail.com>
# Contributor: Greg White <gwhite@kupulau.com>

pkgname=h-navigator
pkgver=4.2.0
pkgrel=1
pkgdesc='H Navigator is a highly-modified, privacy-hardened service runtime and web browser for H-Linux, built on Brave Origin (nightly).'
arch=(x86_64)
url='https://www.freedompublishersunion.net/h-linux.html'
license=('MPL2')
depends=('gtk3' 'nss' 'alsa-lib' 'libxss' 'ttf-font')
optdepends=('cups: Printer support'
            'mesa: Hardware accelerated rendering'
            'mesa-amber: Alternate hardware accelerated rendering'
            'libglvnd: Support multiple different OpenGL drivers at any given time'
            'libgnome-keyring: gnome keyring support')
provides=("${pkgname}")
conflicts=('brave-nightly-bin')
replaces=('brave-nightly-bin')
source=("$pkgname.sh")
options=(!strip)
source_x86_64=("https://github.com/brave/brave-browser/releases/download/v1.94.72/brave-browser-nightly_1.94.72_amd64.deb")
sha512sums=('SKIP')
sha512sums_x86_64=('SKIP')

prepare() {
  mkdir -p h-navigator
  tar xf data.tar.xz -C h-navigator
  # Delete unneeded cron job <<< an Arch/CachyOS leftover
  rm -rf brave/opt/brave.com/brave-nightly/cron
  # Change Brave > H Navigator .desktop
  mv h-navigator/usr/share/applications/brave-browser-nightly.desktop h-navigator/usr/share/applications/h-navigator.desktop
  # Use our script to launch (allows overriding flags, sets up data dir) <<< an Arch/CachyOS leftover
  sed -i "s/\/usr\/bin\/brave-browser-nightly/\/usr\/bin\/h-navigator/g" h-navigator/usr/share/applications/h-navigator.desktop
  # Change brave.com inside dir string > hlinux
  mv h-navigator/opt/brave.com h-navigator/opt/hlinux
}

package() {
    cp -a --reflink=auto h-navigator/opt "$pkgdir/opt"
    cp -a --reflink=auto h-navigator/usr "$pkgdir/usr"
    
    install -Dm0755 "$pkgname.sh" "$pkgdir/usr/bin/h-navigator"
    install -Dm0644 "h-navigator/opt/hlinux/brave-nightly/product_logo_128_nightly.png" "$pkgdir/usr/share/pixmaps/brave-browser-nightly.png"
    install -Dm0664 -t "$pkgdir/usr/share/licenses/$pkgname" "h-navigator/opt/hlinux/brave-nightly/LICENSE"
    # allow firejail users to get the suid sandbox working <<< an Arch/CachyOS leftover
    chmod 4755 "$pkgdir/opt/hlinux/brave-nightly/chrome-sandbox"
}
