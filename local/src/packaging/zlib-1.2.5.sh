#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=zlib
VER=1.2.5
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/compress"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	echo skip > /dev/null
}

post_configure() {
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	mkdir -p ${INSTALL_TARGET}/bin &&
	${XMINGW}/cross make install \
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	-f win32/Makefile.gcc SHARED_MODE=1 "BINARY_PATH=${INSTALL_TARGET}/bin" "INCLUDE_PATH=${INSTALL_TARGET}/include" "LIBRARY_PATH=${INSTALL_TARGET}/lib"
}

pre_pack() {
	ln -f -s "${INSTALL_TARGET}/lib/libzdll.a" "${INSTALL_TARGET}/lib/libz.dll.a"
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib`

#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

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

