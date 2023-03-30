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
	#XLIBRARY_SET="set list"

	# package に返す変数。
	MOD=libarchive
	[ "" = "${VER}" ] && VER=3.6.2
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/compress"
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
bz2
libiconv
libxml2
lzma
zlib
zstd
EOS
}

optional_dependencies() {
	cat <<EOS
lz4
lzo
mbedtls
nettle
openssl
pcre
EOS
}

license() {
	cat <<EOS
2-Clause BSD License

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
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" \
		--disable-xattr --disable-acl \
		--without-bz2lib --without-lz4 --without-lzo2 \
		--without-mbedtls --without-nettle --without-openssl \
		--enable-posix-regex-lib=libpcre2-posix \
		--without-expat

#		--enable-posix-regex-lib=libpcreposix \
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
#	bash ${XMINGW}/replibtool.sh shared
	# __stdcall な関数を適切にエクスポートできない場合の対処。
#	bash ${XMINGW}/replibtool.sh stdcall
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
#	bash ${XMINGW}/replibtool.sh static-libgcc
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
	echo skip > /dev/null
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make all install
}

run_make_test() {
	echo skip > /dev/null
}

run_make_example() {
	echo skip > /dev/null
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*

	sed -i "${INSTALL_TARGET}"/lib/pkgconfig/libarchive.pc \
		-e 's|^\w\+.private:|#\0|'
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/man/man[35] &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,exe.manifest,exe.local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}" 
#	put_exclude_files 
}



