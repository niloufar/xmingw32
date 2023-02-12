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

	# [4.4.0] mingw-w64 への対応が十分でない。
	if [[ -f "gsk/ngl/fp16.c" ]]
	then
		sed -i.orig gsk/ngl/fp16.c \
			-e '/^#if defined(_MSC_VER) /,/^\/\* based on info from / {' \
				-e 's/_MSC_VER/_WIN32/' \
				-e '/^\/\*/i#include <intrin.h>' \
			-e '}'
	fi
}

run_configure() {
local gtk4_40_flags=""
	case "${VER}" in
		"4.40."*)
			gtk4_40_flags="-Dprint-cloudprint=disabled -Dxinerama=disabled"
			;;
	esac
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Doptimization=2 \
		-Dwin32-backend=true -Dmacos-backend=false \
		-Dwayland-backend=false -Dx11-backend=false \
		-Dmedia-ffmpeg=disabled -Dmedia-gstreamer=disabled \
		-Dprint-cups=disabled \
		-Dvulkan=disabled \
		-Dcloudproviders=disabled \
		-Dinstall-tests=false \
		-Dgtk_doc=true -Dintrospection=enabled \
		${gtk4_40_flags}
}

post_configure() {
	# [4.4.0] windows では利用できない関数が参照され、エラーになる。
	# [4.6.1] ld -z noexecstack が問題になる。 gcc -Wa,--noexecstack する解決策を採用したいが、追いきれていない。
	sed -i.orig _build/build.ninja \
		-e '/^\s\+COMMAND\s*.\+gi-docgen/ {' \
			-e 's/ --fatal-warnings /  /' \
		-e '}' \
		-e '/^\s*COMMAND = .*\/ld / s/ -z noexecstack /  /'
	# [4.6.1] win32 でリンクエラーになる。
	# objcopy --add-symbol _g_binary_gtkdemo_resource_data=.data:0 を
	# 行うが、元の meson-generated_.._gtkdemo_resources.c.obj もリンクしようとする。
	sed -i _build/build.ninja \
		-e '/build demos\/.*\.exe: c_LINKER / s# demos/\(gtk-demo\|widget-factory\)/gtk4-[^ ]\+\.exe\.p/meson-generated_\.\._\(gtkdemo\|widgetfactory\)_resources\.c\.obj#  #'
}

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
	pack_archive "${__BINZIP}" bin/*.dll lib/girepository-* share/glib-2.0/schemas/org.gtk.gtk4.Settings.* "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/gir-* &&
	pack_archive "${__DOCZIP}" share/doc &&
	pack_archive "${__TOOLSZIP}" bin/gtk4-{builder,encode,icon,node-editor,print,query,update}*.{exe,exe.manifest,exe.local} share/{gtk-4.0,icons,locale} share/glib-2.0/schemas/*Demo* share/applications share/metainfo/org.gtk.{Icon,gtk4.NodeEditor,Print,Widget}*.appdata.xml &&
	pack_archive "${__DEMOZIP}" bin/gtk4-{demo,widget-factory}*.{exe,exe.manifest,exe.local} share/metainfo/*Demo* &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" &&
	store_packed_archive "${__DEMOZIP}" &&
	put_exclude_files share/gettext/its
}



