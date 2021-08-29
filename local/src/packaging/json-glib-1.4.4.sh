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
	MOD=json-glib
	[ "" = "${VER}" ] && VER=1.4.4
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
glib
EOS
}

optional_dependencies() {
	cat <<EOS
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

:run_patch() {
	# [1.4.2] クロス コンパイルを考慮する＋もろもろ。
	# [1.4.4] mesontest コマンドのチェックを削除する。
	sed -i.orig configure \
		-e 's!^exec ${MESON} !\0--cross-file _meson.cross-file --buildtype release --strip !' \
		-e 's/^sanitycheck MESONTEST /#\0/'
}

run_configure() {
	MESONTEST="meson test" \
	CFLAGS="`${XMINGW}/cross --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype release --default-library=shared \
		-Ddocs=true -Dman=false \
		-Dintrospection=enabled
}

run_make() {
	WINEPATH="$PWD/_build/json-glib" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="$PWD/_build/json-glib" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/girepository-1.0 share/locale share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/gir-* &&
	pack_archive "${__DOCZIP}" share/gtk-doc/ &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files bin/installed-tests libexec share/installed-tests
}



