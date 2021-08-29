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
	XLIBRARY_SET="gtk"

	# package に返す変数。
	MOD=gtk
	[ "" = "${VER}" ] && VER=4.2.1
	[ "" = "${REV}" ] && REV=1
#	[ "" = "${PATCH}" ] && PATCH=2.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP="${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}"
	__DEVZIP="${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}"
	__DOCZIP="${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}"
	__TOOLSZIP="${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}"
	__DEMOZIP=${MOD}-${VER}-${REV}-demo_${ARCHSUFFIX}

	# アーキテクチャを指定しない場合は NOARCH=yes する。
#	NOARCH=yes
}

dependencies() {
	cat <<EOS
cairo
fribidi
gdk-pixbuf
glib
gobject-introspection
graphene
harfbuzz
libepoxy
pango
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
GNU LIBRARY GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# Linux ではファイル名の大文字小文字は区別される。
	for f in gdkwin32cursor.h gdkcairocontext-win32.c gdkhdataoutputstream-win32.c
	do
		sed -i.orig gdk/win32/${f} \
			-e '/#include / s/<Windows.h>/<windows.h>/'
	done

	# shooter を作成しない。
	cat /dev/null > docs/tools/meson.build
}

# meson を使用する場合。
# run_configure を削除し、下記関数定義行頭のコロンを削除する。
run_configure() {
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-D_WIN32_WINNT=_WIN32_WINNT_VISTA \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Doptimization=2 \
		-Dwin32-backend=true \
		-Dmedia-ffmpeg=disabled -Dmedia-gstreamer=disabled \
		-Dprint-cups=disabled -Dprint-cloudprint=disabled \
		-Dvulkan=disabled \
		-Dxinerama=disabled -Dcloudproviders=disabled \
		-Dinstall-tests=false \
		-Dgtk_doc=true -Dintrospection=enabled
}

# meson を使用する場合。
# run_make を削除し、下記関数定義行頭のコロンを削除する。
run_make() {
	WINEPATH="${PWD}/_build/gtk" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="${PWD}/_build/gtk" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING* AUTHORS*
}

run_pack() {
	# *-bin はランタイムなどアプリに必要なものをまとめる。
	# dev-* はビルドに必要なものをまとめる。ツールはビルド環境のものを使用し、含めない。
	# *-tools はその他の実行ファイル等をまとめる。
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/girepository-* "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/gir-* &&
	pack_archive "${__DOCZIP}" share/doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,exe.manifest,exe.local} share/{glib-2.0/schemas,gtk-4.0,icons,locale,metainfo} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	put_exclude_files share/{applications,gettext/its}
}



