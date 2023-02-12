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
	XLIBRARY_SET="gtk"

	# package に返す変数。
	MOD=gtk+
	[ "" = "${VER}" ] && VER=3.24.36
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
	__DEMOZIP=${MOD}-${VER}-${REV}-demo_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
atk
cairo
gdk-pixbuf
gettext-runtime
glib
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

run_configure() {
	# ビルドに gtk-update-icon-cache, gtk-query-immodules-3.0 が必要。
	# --enable_gtk2_dependency を付けなければ gtk/native の native-update-icon-cache をビルドする。
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared \
		-Doptimization=2 \
		-Dwin32_backend=true -Dquartz_backend=false \
		-Dwayland_backend=false -Dx11_backend=false \
		-Dxinerama=no \
		-Dcloudproviders=false \
		-Dinstalled_tests=false \
		-Dgtk_doc=true -Dintrospection=true
}

run_make() {
	WINEPATH="./gtk;./gdk" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="./gtk;./gdk" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
local TESTZIP="${MOD}-${VER}-${REV}-test_${ARCHSUFFIX}"
	pack_archive "${TESTZIP}" tests/*.{exe,png,xpm,ui,css} tests/.libs/*.exe &&
	store_packed_archive "${TESTZIP}"

	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll bin/gtk-query-immodules-3.0.exe etc `find lib -name \*.dll` lib/girepository-* share/{locale,themes} share/glib-2.0/schemas/org.gtk.Settings.* "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include `find lib -name \*.def -or -name \*.a` lib/pkgconfig share/{aclocal,gettext/its,gir-*,glib-2.0,gtk-3.0} &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/gtk-{builder-tool,encode-symbolic-svg,launch,query-settings,update-icon-cache}.exe &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}" && 

	pack_archive "${__DEMOZIP}" bin/gtk3-{demo,demo-application,icon-browser,widget-factory}.exe share/glib-2.0/schemas/*{Demo,example}* share/applications share/icons &&
	store_packed_archive "${__DEMOZIP}" #&&

#	put_exclude_files share/applications/*.desktop
}



