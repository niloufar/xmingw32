#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=jpeg
	[ "" = "${VER}" ] && VER=9
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}src.v${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
Independent JPEG Group's

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="-Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make all install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


