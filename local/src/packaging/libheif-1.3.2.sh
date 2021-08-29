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
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=libheif
	[ "" = "${VER}" ] && VER=1.3.2
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
libde265
EOS
}

optional_dependencies() {
	cat <<EOS
jpeg
libfuzzer
libpng
x265
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

run_patch() {
	[1.7.0] AOM は使わない。
	sed -i.orig configure \
		-e 's|^$as_echo "#define HAVE_AOM 1"|#\0|' \
		-e 's|have_aom="yes"|have_aom="no"|'
}

run_configure_win32() {
#local ver="`sed configure.ac -ne '/^AC_INIT(\[libheif\]/ {' -e 's/.*\[\([0-9.]\+\)\].*/\1/p' -e '}'`"
#local gccver="`$XMINGW/cross gcc --version | head -n 1 | cut '-d ' -f 3`"
	# [1.3.2] mingw-w64-gcc 8.[13].0 のバグか #include <thread> の
	#  __x._M_thread == __y._M_thread が no match for ‘operator==’ になる。
	case "${VER}" in
	"1.3."*|"1.4."*|"1.5.1"|"1.6."[12]|"1.7.0")
		run_configure__ --disable-multithreading
		;;
	*)
		run_configure__ --enable-multithreading
		;;
	esac
}

run_configure_win64() {
	run_configure__ --enable-multithreading
}

run_configure__() {
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
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" \
		--disable-libfuzzer \
		--disable-aom --disable-rav1e \
		--enable-libde265 --enable-x265 --enable-gdk-pixbuf \
		"$@"
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
	bash ${XMINGW}/replibtool.sh shared
	# __stdcall な関数を適切にエクスポートできない場合の対処。
#	bash ${XMINGW}/replibtool.sh stdcall
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
#	bash ${XMINGW}/replibtool.sh static-libgcc
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
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
local add_tools
	if [[ -d "${INSTALL_TARGET}/share/man/man1" ]]
	then
		add_tools="share/man/man1"
	fi

	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} ${add_tools} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
	put_exclude_files share/{mime,thumbnailers} || return 0
}



