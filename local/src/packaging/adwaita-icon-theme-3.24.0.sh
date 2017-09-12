#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=adwaita-icon-theme
	[ "" = "${VER}" ] && VER=3.24.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP="${MOD}-${VER}-${REV}-bin"

	# アーキテクチャを指定しない。
	NOARCH=yes
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
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
Creative Commons — Attribution-ShareAlike 3.0 Unported — CC BY-SA
Version 3.0
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
local name
	# name=`find_archive "${__ARCHIVEDIR}" ${__PATCH_ARCHIVE}` &&
	# 	patch_debian "${__ARCHIVEDIR}/${name}"
	echo skip > /dev/null
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}" #--enable-l-xl-variants
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING* AUTHORS "${docdir}/."
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" share/{doc,icons} &&
	store_packed_archive "${__BINZIP}" &&
	put_exclude_files share/pkgconfig
}



