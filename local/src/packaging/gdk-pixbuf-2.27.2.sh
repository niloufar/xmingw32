#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=gdk-pixbuf
	[ "" = "${VER}" ] && VER=2.27.2
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
gettext-runtime
glib
libiconv
libjpeg
libpng
tiff
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# libpng16 を使用できるようにする。
	sed -i.orig 's/in libpng15/in libpng16 libpng15/' configure
#	echo skip > /dev/null
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-gdiplus --with-included-loaders --enable-debug=yes --enable-explicit-deps=no --disable-gtk-doc --disable-static --without-x --disable-xlib --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh
	# xlib 系をビルドしようとするので対象から外す。
	sed -i -e 's/^\(DIST_SUBDIRS = \)\(gdk-pixbuf-xlib\)/\1# \2/' \
		-e 's/^\(am__append_1 = \)\(gdk-pixbuf-xlib\)/\1# \2/' \
		contrib/Makefile
	# tests でいろいろエラーになるため外す。
	sed -i -e 's/^\(SUBDIRS = .\+\) tests /\1 /' Makefile
}

run_make() {
	${XMINGW}/cross make install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/locale &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe share/man &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


