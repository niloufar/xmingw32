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
	XLIBRARY_SET="gimp2.10"

	# package に返す変数。
	MOD=gimp-data-extras
	[ "" = "${VER}" ] && VER=2.0.4
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/plugins"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BRUSHESZIP="${MOD}-brushes-${VER}-${REV}-bin"
	__PATTERNSZIP="${MOD}-patterns-${VER}-${REV}-bin"
	__SCRIPTSZIP="${MOD}-scripts-${VER}-${REV}-bin"
#	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
#	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
#	__DOCZIP="${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}"
#	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"

	# アーキテクチャを指定しない場合は NOARCH=yes する。
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
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	sed -i.orig configure \
		-e "s|^\(GIMP_DATA_DIR=\).*|\1\"${INSTALL_TARGET}/share/gimp/2.0\"|"
}

run_configure() {
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BRUSHESZIP}" "${LICENSE_DIR}" share/gimp/2.0/brushes &&
	pack_archive "${__PATTERNSZIP}" "${LICENSE_DIR}" share/gimp/2.0/patterns &&
	pack_archive "${__SCRIPTSZIP}" "${LICENSE_DIR}" share/gimp/2.0/scripts &&
	store_packed_archive "${__BRUSHESZIP}" &&
	store_packed_archive "${__PATTERNSZIP}" &&
	store_packed_archive "${__SCRIPTSZIP}"
#	put_exclude_files 
}



