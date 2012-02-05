#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=cairo
VER=1.10.2
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
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
	# [cairo-bugs] [Bug 30277] New: Compilation failure due to ffs() when compiling for MinGW
	# http://lists.cairographics.org/archives/cairo-bugs/2010-September/003846.html
	sed -i.orig -e 's/^#elif HAS_ATOMIC_OPS/\0\n#ifdef __MINGW32__\n#define ffs __builtin_ffs\n#endif/' src/cairo.c
}

run_configure() {
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	png_REQUIRES=libpng15 \
	pixman_LIBS="-Wl,${XLIBRARY}/gtk+/lib/libpixman-1.a" \
	CC='gcc -mtune=pentium4 -mthreads -mms-bitfields -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-x --disable-xlib --disable-static --enable-ft=yes --enable-win32 --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	cp -p src/cairo.def "${INSTALL_TARGET}/lib" &&

	mkdir -p "${INSTALL_TARGET}/share/doc/${THIS}" &&
	cp -p COPYING COPYING-LGPL-2.1 COPYING-MPL-1.1 "${INSTALL_TARGET}/share/doc/${THIS}"
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll "share/doc/${THIS}" &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gtk-doc/ &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} gettext-runtime glib pkg-config pixman libpng fontconfig freetype`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`
#ZLIB=`latest --arch=${ARCH} zlib`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

#export XLIBRARY_SET=${XLIBRARY}/gimp_build_set

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

