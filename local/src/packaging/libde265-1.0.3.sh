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
	# package に返す変数。
	MOD=libde265
	[ "" = "${VER}" ] && VER=1.0.3
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
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
libswscale
libvideogfx
qt
sdl
EOS
}

license() {
	cat <<EOS
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	# -static-libstdc++ と -lstdc++ の同時指定が multiple definition に
	# なるため -Wl,--allow-multiple-definition している。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CFLAGS="`${XMINGW}/cross --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="`${XMINGW}/cross --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s \
	-Wl,--allow-multiple-definition" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --disable-dec265 --disable-sherlock265
}

post_configure() {
	# -static-libstdc++ と -lstdc++ の同時指定が multiple definition に
	# なるため -lstdc++ を削除している。
	# libtool の postdeps から削除してはいけない。
	sed -i.orig {acceleration-speed,dec265,enc265,sherlock265,tools}/Makefile -e 's/ -lstdc++//'
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
#	put_exclude_files 
}



