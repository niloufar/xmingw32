#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=atk
VER=2.3.3
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
	#lt_cv_deplibs_check_method='pass_all' \
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-gtk-doc --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# ./atk/atk.def の1行目が -e EXPORTS になってしまう。頭の -e を削除する。
	sed -i -e 's/^\(\s\+(echo\) -e \(EXPORTS;\)/\1 \2/' ./atk/Makefile
}

pre_make() {
	(cd atk && ${XMINGW}/cross make atkmarshal.h atkmarshal.c)
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	echo skip > /dev/null
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll &&
	pack_archive "${DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib gettext-runtime glib`

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

