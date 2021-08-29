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
	# cross に渡す変数。
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=libmng
	[ "" = "${VER}" ] && VER=1.0.10
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
jpeg
lcms
EOS
}

license() {
	cat <<EOS
libmng LICENSE

EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# configure を生成する。
local autogen=./unmaintained/autogen.sh 
	# libmng 1 系のための処理。 2 系から不要。
	if [ -e "${autogen}" ]
	then
		"${autogen}"
	fi
#	echo skip > /dev/null
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-gtk-doc --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
	# __stdcall な関数を適切にエクスポートできない場合の対処。
	bash ${XMINGW}/replibtool.sh shared stdcall
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。

	# __stdcall のための修正。
	sed config.h -i.orig -e 's/MNG_BUILD_SO/MNG_BUILD_DLL/'
}

run_make() {
	${XMINGW}/cross make install
}

run_pack() {
local pc
	cd "${INSTALL_TARGET}" &&
	if [ -e "lib/pkgconfig" ]
	then
		pc="lib/pkgconfig"
	fi &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} ${pc} share/man/man{3,5} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



