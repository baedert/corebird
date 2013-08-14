
pkgname=corebird-git
pkgver=20130315
pkgrel=1
_realver=0.05
pkgdesc="Gtk+ Twitter client"
arch=('i686' 'x86_64')
license=('LGPL')
url="https://bitbucket.org/baedert/corebird"
depends=('gtk3>=3.9'
     'glib2>=2.38'
     'rest>=0.7' #media upload needs rest-git from the AUR
     'libgee'
     'sqlite3'
     'libsoup>=2.4'
     'libnotify'
     'sqlheavy-git'
     'json-glib')
makedepends=('vala' 'git' 'cmake')

_gitroot="https://bitbucket.org/baedert/corebird.git"
_gitname="corebird"

build() {
  cd $srcdir
  msg "connecting to bitbucket GIT server"

  if [ -d $srcdir/$_gitname ] ; then
    cd $_gitname && git pull origin
    msg "the local files are updated"
  else
    git clone $_gitroot
  fi

  msg "GIT checkout done or server timeout"
  msg "Starting make ..."

  rm -rf "$srcdir/$_gitname-build"
  git clone "$srcdir/$_gitname" "$srcdir/$_gitname-build"
  cd $srcdir/$_gitname-build

  msg "Starting build..."
  ./compile-resources.sh
  cmake . -DCMAKE_INSTALL_PREFIX=/usr
  make
}

package() {
  cd "$srcdir/$_gitname-build"
  make DESTDIR=$pkgdir install
}

