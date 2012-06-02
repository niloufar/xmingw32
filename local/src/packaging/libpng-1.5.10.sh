#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=libpng
VER=1.5.10
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"
LIBNAME="libpng15"

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
	# ディレクトリーを掘って作業できない。 configure で弾かれる。
	echo skip > /dev/null
}

run_configure() {
	CC='gcc -mtune=pentium4 -mthreads -mms-bitfields -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` -Wl,-s \
	-Wl,--enable-auto-image-base" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --without-binconfigs --prefix="${INSTALL_TARGET}"
}


post_configure() {
	bash ${XMINGW}/replibtool.sh
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local NAME="${INSTALL_TARGET}/bin/${LIBNAME}-config"
	cp libpng-config "${NAME}" &&
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${NAME}"
}

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive ${BINZIP} bin/*.dll &&
	pack_archive ${DEVZIP} bin/${LIBNAME}-config include/${LIBNAME} lib/${LIBNAME}*.a lib/pkgconfig/${LIBNAME}.pc share &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}"
}


(

set -x

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

