#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=babl
	if [ "" = "${VER}" ]
	then
	VER=0.1.10
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
}

dependencies() {
	cat <<EOS
EOS
}

dependencies_opt() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	# timespec は sys/timeb.h と pthread.h で定義されている。
	# 	pthread.h の定義を寝かせた。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	-DHAVE_STRUCT_TIMESPEC=1" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --enable-mmx --enable-sse --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# tests/Makefile の -pthread を -lpthread に変更する。
	sed -i.orig -e 's/ -pthread/ -lpthread/' tests/Makefile &&
	bash ${XMINGW}/replibtool.sh
}

pre_make() {
	# limits.h は標準ヘッダーファイル。 values.h は処理系依存。
	sed -i.orig -e "s|^#include <values.h>|#include <limits.h>|" babl/babl-palette.c
}

run_make() {
	${XMINGW}/cross make SHREXT=.dll all install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/babl-0.1/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/babl-0.1/*.a lib/pkgconfig &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


