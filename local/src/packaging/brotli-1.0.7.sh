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
	MOD=brotli
	[ "" = "${VER}" ] && VER=1.0.7
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
EOS
}

license() {
	cat <<EOS
MIT License

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

# cmake を使用する場合。
# run_configure を削除し、下記関数定義行頭のコロンを削除する。
run_configure() {
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	"-DCMAKE_EXE_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" LICENSE*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,exe.manifest,exe.local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
#	put_exclude_files 
}



