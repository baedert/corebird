
pkgname=corebird-git
pkgver=20130315
pkgrel=1
_realver=0.05
pkgdesc="Gtk+ Twitter client"
url="http://pango.com"
arch=('i686' 'x86_64')
license=('LGPL')
depends=('gtk3>=3.6'
		 'glib2>=2.32'
		 'rest>=0.7' #media upload needs rest-git from the AUR
		 'libgee'
		 'sqlite3'
		 'libsoup>=2.4'
		 'libnotify')
makedepends=('vala' 'git' 'cmake')

_gitroot="https://baedert@bitbucket.org/baedert/corebird.git"
_gitname="corebird"

build() {
	cd $srcdir
	msg "connecting to git.gnome.org GIT server"

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
	cmake .
	make
}

package() {
	cd "$srcdir/$_gitname-build"
	make DESTDIR=$pkgdir install
}

