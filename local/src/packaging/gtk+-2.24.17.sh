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
	[ "" = "${VER}" ] && VER=2.24.17
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
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

optional_dependencies() {
	cat <<EOS
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	if gtk-update-icon-cache --help | grep -ie "--include-image-data" > /dev/null
	then
		# ignore
		echo skip >/dev/null
	else
		# ネイティブで動作する gtk-update-icon-cache を作成する。
		# 2.24.24 から gtk-update-icon-cache が新しくなり、
		# 古いバージョンと一部非互換になった。
		./configure &&
		(
		cd gtk &&
		make gtk-update-icon-cache && 
		cp gtk-update-icon-cache _gtk-update-icon-cache &&
		make clean
		)
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" \
		--without-x --with-gdktarget=win32 \
		--with-included-immodules \
		--enable-debug=yes \
		--enable-explicit-deps=no \
		--disable-schemas-compile --disable-glibtest --disable-cups \
		--disable-gtk-doc --enable-introspection
}

post_configure() {
	if [ -e "${PWD}/gtk/_gtk-update-icon-cache" ]
	then
		for mf in `find . -name Makefile`
		do
			sed -i -e "s!^\(GTK_UPDATE_ICON_CACHE\) =.*!\\1 =\"${PWD}/gtk/_gtk-update-icon-cache\"!" "${mf}"
		done
	fi

	# [2.24.33]
	sed -i.orig gtk/Makefile \
		-e '/^Gtk-2.0.gir:/ s/\$(INTROSPECTION_SCANNER)//'

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
	WINEPATH="${PWD}/gdk/.libs;${PWD}/gtk/.libs" \
	${XMINGW}/cross make all install
}

run_pack() {
	if [ -e "${PWD}/gtk/_gtk-update-icon-cache" ]
	then
		cp "${PWD}/gtk/_gtk-update-icon-cache" "${INSTALL_TARGET}/bin/."
	fi &&

	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll etc `find lib -name \*.dll` lib/girepository-* share/{locale,themes} &&
	pack_archive "${__DEVZIP}" bin/_* bin/gtk-builder-convert include `find lib -name \*.def -or -name \*.a` lib/gtk-2.0/include lib/pkgconfig share/{aclocal,gir-*,gtk-2.0,gtk-doc} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


