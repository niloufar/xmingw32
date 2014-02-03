#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=libpng
	if [ "" = "${VER}" ]
	then
	VER=1.6.0
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__LIBNAME="libpng16"

	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
}

dependencies() {
	cat <<EOS
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
	LDFLAGS="`${XMINGW}/cross --ldflags` -Wl,-s \
	-Wl,--enable-auto-image-base" \
	CFLAGS="-pipe -fpic -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --without-binconfigs --prefix="${INSTALL_TARGET}"
}


post_configure() {
	bash ${XMINGW}/replibtool.sh
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local NAME="${INSTALL_TARGET}/bin/${__LIBNAME}-config"
	cp libpng-config "${NAME}" &&
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${NAME}"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive ${__BINZIP} bin/*.dll &&
	pack_archive ${__DEVZIP} bin/${__LIBNAME}-config include/${__LIBNAME} lib/${__LIBNAME}*.a lib/pkgconfig/${__LIBNAME}.pc share &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


