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
	MOD=freetype
	if [ "" = "${VER}" ]
	then
	VER=2.4.11
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}
}

dependencies() {
	cat <<EOS
zlib
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CC_BUILD=build-cc \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# freetype6.dll の形にするため書き換える。
	sed -i.orig -e 's#^soname_spec=.*#soname_spec="\\\`echo "\\\${libname}\\\${versuffix}" | \\\$SED -e "s/^lib//" -e "s/-//"\\\`\\\${shared_ext}"#' builds/unix/libtool
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${INSTALL_TARGET}/bin/freetype-config"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" bin/*-config include lib/*.a lib/pkgconfig share/aclocal &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


