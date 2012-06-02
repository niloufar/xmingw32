#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=gtk+
VER=2.24.10
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	# glib-compile-schemas は入手が難しくまた tests を作らないなら必要ない。
#	sed -i -e 's/^\s\+\(as_fn_error $? "glib-compile-schemas not found\)/echo \1/' configure
	echo skip > /dev/null
}

run_configure() {
	GLIB_GENMARSHAL="${XLIBRARY}/gtk+/bin/_glib-genmarshal" \
	GLIB_COMPILE_SCHEMAS="${XLIBRARY}/gtk+/bin/_glib-compile-schemas" \
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-x --with-gdktarget=win32 --with-included-immodules --enable-debug=yes --enable-explicit-deps=no --disable-schemas-compile --disable-glibtest --disable-gtk-doc --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# -lgmodule-2.0 を渡してくれないので。
	sed -i.orig -e 's/ -lglib-2\.0/ -lgmodule-2.0\0/' gtk/Makefile &&
	bash ${XMINGW}/replibtool.sh
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll etc `find lib -name \*.dll` share/{locale,themes} &&
	pack_archive "${DEVZIP}" bin/gtk-builder-convert include `find lib -name \*.def -or -name \*.a` lib/gtk-2.0/include lib/pkgconfig share/{aclocal,gtk-2.0,gtk-doc} &&
	pack_archive "${TOOLSZIP}" bin/*.{exe,manifest} &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib pkg-config atk cairo freetype fontconfig pango gdk-pixbuf libpng`
#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#LIBPNG=`latest --arch=${ARCH} libpng`
#ZLIB=`latest --arch=${ARCH} zlib`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

export XLIBRARY_SET=${XLIBRARY}/gimp_build_set

run_expand_archive &&
cd "${DIRECTORY}" &&
pre_configure &&
run_configure &&
post_configure &&

pre_make &&
run_make &&

pre_pack &&
run_pack_archive &&

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.

