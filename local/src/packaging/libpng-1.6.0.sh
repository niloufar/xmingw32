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
	MOD=libpng
	[ "" = "${VER}" ] && VER=1.6.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__LIBNAME="libpng16"

	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
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
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp LICENSE "${docdir}/."

local NAME="${INSTALL_TARGET}/bin/${__LIBNAME}-config"
	cp libpng-config "${NAME}" &&
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${NAME}"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive ${__BINZIP} bin/*.dll share/doc &&
	pack_archive ${__DEVZIP} bin/${__LIBNAME}-config include/${__LIBNAME} lib/${__LIBNAME}*.a lib/pkgconfig/${__LIBNAME}.pc share/man &&
	pack_archive ${__TOOLSZIP} bin/png*.exe &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&

	# シンボリック リンクは除外する。必要なときは ln -s する。
	put_exclude_files bin/libpng-config include/png{,conf,libconf}.h lib/libpng.dll.a lib/pkgconfig/libpng.pc
}


