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
	MOD=libffi
	[ "" = "${VER}" ] && VER=3.0.13
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/etc"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
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
libffi

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
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -fpic -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" LICENSE
}

run_pack() {
local include_dir
	# [3.3] include フォルダーの場所が変更された。
	if [[ -d "${INSTALL_TARGET}/include" ]]
	then
		include_dir="include"
	else
		include_dir="lib/${DIRECTORY}"
	fi
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" ${include_dir} lib/*.{def,a} lib/pkgconfig share/{info,man/man3} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


