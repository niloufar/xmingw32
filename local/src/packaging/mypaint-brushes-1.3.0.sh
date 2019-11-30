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
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=mypaint-brushes
	[ "" = "${VER}" ] && VER=1.3.0
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
#	__DOCZIP="${MOD}-${VER}-${REV}-doc"
#	__TOOLSZIP="${MOD}-${VER}-${REV}-tools"

	# アーキテクチャを指定しない場合は NOARCH=yes する。
#	NOARCH=yes
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
Creative Commons
CC0 1.0 Universal
GNU GENERAL PUBLIC LICENSE
Version 2
GNU GENERAL PUBLIC LICENSE
Version 2+
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	if [[ ! -e "configure" ]]
	then
		./autogen.sh
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local share_dir="${INSTALL_TARGET}/share"
local lib_dir="${INSTALL_TARGET}/lib"
local share_pkgconfig_dir="${share_dir}/pkgconfig"
local lib_pkgconfig_dir="${lib_dir}/pkgconfig"
	if [[ -d "${share_pkgconfig_dir}" ]]
	then
		mkdir -p "${lib_dir}" &&
		if [[ -d "${lib_pkgconfig_dir}" ]]
		then
			rm -r "${lib_pkgconfig_dir}"
		fi &&
		mv --force "${share_pkgconfig_dir}" "${lib_dir}/."
	fi &&

	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING* Licenses*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" share/doc share/mypaint-data &&
	pack_archive "${__DEVZIP}" lib/pkgconfig &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
#	put_exclude_files 
}



