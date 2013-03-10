#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=gdk-pixbuf
VER=2.26.0
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
	echo skip > /dev/null
}

run_configure() {
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -mtune=pentium4 -mthreads -msse -mno-sse2 -O2 -fomit-frame-pointer -ffast-math `${XMINGW}/cross --cflags`" \
	${XMINGW}/cross-configure --without-gdiplus --with-included-loaders --without-libjasper --enable-debug=yes --enable-explicit-deps=no --disable-gtk-doc --disable-static --without-x --disable-xlib --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh
	# xlib 系をビルドしようとするので対称から外す。
	sed -i -e 's/^\(DIST_SUBDIRS = \)\(gdk-pixbuf-xlib\)/\1# \2/' \
		-e 's/^\(am__append_1 = \)\(gdk-pixbuf-xlib\)/\1# \2/' \
		contrib/Makefile
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
	pack_archive "${BINZIP}" bin/*.dll lib/gdk-pixbuf-2.0 &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${TOOLSZIP}" bin/*.exe &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib glib pkg-config libpng`
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
