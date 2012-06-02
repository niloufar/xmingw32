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
VER=1.12.0
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
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	png_REQUIRES=libpng15 \
	pixman_LIBS="-Wl,${XLIBRARY}/gtk+/lib/libpixman-1.a" \
	CC='gcc -mtune=pentium4 -mthreads -mms-bitfields -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-x --disable-xlib --disable-xcb --disable-static --enable-ft=yes --enable-win32 --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh
}

pre_make() {
	# 定義の衝突。
	sed -i.orig -e 's|^typedef SSIZE_T ssize_t;|/* typedef SSIZE_T ssize_t; */|' util/cairo-missing/cairo-missing.h &&
	# 一般的な関数名を使用しているため定義が衝突する。
	sed -i.orig -e "s/_writen\? /do\0/" test/any2ppm.c &&
	# alarm 関数は未定義のはず。 
	sed -i.orig -e "s/^\(#define HAVE_ALARM\) 1/\1 0/" config.h &&
	# _cairo_win32_print_gdi_error が export されない。
	(patch --force --quiet -p 0 <<\EOF ; return 0) &&
--- src/Makefile
+++ src/Makefile
@@ -2655,6 +2655,7 @@
 	$(EGREP) '^cairo_.* \(' | \
 	sed -e 's/[ 	].*//' | \
 	sort; \
+	echo _cairo_win32_print_gdi_error; \
 	echo LIBRARY libcairo-$(CAIRO_VERSION_SONUM).dll; \
 	) >$@
 	@ ! grep -q cairo_ERROR $@ || ($(RM) $@; false)
EOF
	# いろいろ面倒だったので test, perf をビルドしないことにした。
	sed -i.orig -e "s/^\(am__append_1 = boilerplate\) .*$/\1/" Makefile
}

run_make() {
	${XMINGW}/cross make all install 
#CAIRO_LDFLAGS="\$(CAIRO_LIBS)" LDADD="-Wl,${XLIBRARY}/gtk+/lib/libpixman-1.a"
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

