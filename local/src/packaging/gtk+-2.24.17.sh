#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=gtk+
	if [ "" = "${VER}" ]
	then
	VER=2.24.17
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
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

dependencies_opt() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-x --with-gdktarget=win32 --with-included-immodules --enable-debug=yes --enable-explicit-deps=no --disable-schemas-compile --disable-glibtest --disable-gtk-doc --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh
}

# win64 ビルドのための特別な処理。
pre_make_win64() {
	# README.win32 によると win64 ビルドは gtk/gtk.def を削除せよとのこと。
	mv gtk/gtk.def gtk/gtk.def.off
	# しかし Makefile の echo -e EXPORTS; が -e EXPORTS と出力しこける。
	(cd gtk &&
	${XMINGW}/cross make gtk.def &&
	sed -i -e 's/^-e //' gtk.def)
}

run_make() {
	${XMINGW}/cross make all install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll etc `find lib -name \*.dll` share/{locale,themes} &&
	pack_archive "${__DEVZIP}" bin/gtk-builder-convert include `find lib -name \*.def -or -name \*.a` lib/gtk-2.0/include lib/pkgconfig share/{aclocal,gtk-2.0,gtk-doc} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


