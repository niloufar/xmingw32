#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCHSUFFIX は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET="gtk"

	# package に返す変数。
	MOD=fribidi
	[ "" = "${VER}" ] && VER=1.0.1
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
#	__DOCZIP="${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}"
	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"

	# アーキテクチャを指定しない場合は NOARCH=yes する。
#	NOARCH=yes
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
glib
EOS
}

license() {
	cat <<EOS
GNU LESSER GENERAL PUBLIC LICENSE
Version 2.1, February 1999
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	# [1.0.2] c2man パッケージが見当たらないため --disable-docs している。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --disable-docs
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
local dev_add
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	if [[ -d "share/man/man3" ]]
	then
		dev_add="${dev_add} share/man/man3"
	fi &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig ${dev_add} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
#	put_exclude_files 
}



