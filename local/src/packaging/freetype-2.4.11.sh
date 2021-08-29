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
	XLIBRARY_SET="gtk"

	# package に返す変数。
	MOD=freetype
	[ "" = "${VER}" ] && VER=2.4.11
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
brotli
bzip2
libpng
harfbuzz
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CC_BUILD="${XMINGW}/cross-host cc" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# shared ファイルを作ってくれない場合の対処。
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
	# libstdc++ を静的リンクする。
	(cd builds/unix/  && bash ${XMINGW}/replibtool.sh shared mix static-libgcc)
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local freetype_config_path="${INSTALL_TARGET}/bin/freetype-config"
	# スクリプト内の prefix を置き換える。
	# [2.9.1] freetype-config がインストールされないようだ。
	if [[ -e "${freetype_config_path}"  ]]
	then
		sed -i "${freetype_config_path}" \
			-e 's#^\(\s*prefix=\).*#\1\"`dirname \$0\`/.."#' \
			-e "s;${INSTALL_TARGET};\${prefix};" \
			-e "s;${XMINGW_BIN}/;;"
	fi
}

run_pack() {
local dev_add
	cd "${INSTALL_TARGET}" &&
	# [2.9.1] man1 が作成されないようだ。
	if [[ -d "share/man/man1" ]]
	then
		dev_add="${dev_add} share/man/man1"
	fi &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" bin/*-config include lib/*.a lib/pkgconfig share/aclocal ${dev_add} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}


