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
	MOD=glib
	if [ "" = "${VER}" ]
	then
	VER=2.37.2
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
gettext-runtime
iconv
libffi
libxml2
zlib
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	make clean 2>&1 > /dev/null
	# ubuntu 13.04 では automake のバージョン不一致によりビルドできない。
	# automake >= 1.10 であり 1.11 はサポートされている。
	# ./autogen.sh
	autoreconf --force --install --verbose
	# ビルドに glib-genmarshal が必要なので先に作成する。
	LIBFFI_CFLAGS=" " LIBFFI_LIBS=" " \
	./configure -enable-silent-rules --disable-gtk-doc --enable-static --disable-shared &&
	(cd glib; make) &&
	(cd gthread; make) &&
	(cd gmodule; make) &&
	(cd gio/inotify; make) &&
	(cd gio/xdgmime; make) &&
	(cd gobject; make libgobject-2.0.la) &&
	(cd gobject; make glib-genmarshal && mv glib-genmarshal _glib-genmarshal) &&
	# ビルドに glib-compile-schemas が必要なので先に作成する。
	(cd gio; make glib-compile-schemas && mv glib-compile-schemas _glib-compile-schemas) &&
	# ビルドに glib-compile-resources が必要なので先に作成する。
	(cd gio; make glib-compile-resources LIBS=-lffi && cp glib-compile-resources _glib-compile-resources) &&
	make clean 2>&1 > /dev/null
}

run_configure() {
	GLIB_GENMARSHAL="${PWD}/gobject/_glib-genmarshal" \
	GLIB_COMPILE_SCHEMAS="${PWD}/gio/_glib-compile-schemas" \
	GLIB_COMPILE_RESOURCES="${PWD}/gio/_glib-compile-resources" \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-silent-rules --disable-gtk-doc --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# tests は作らない。
#	sed -i -e 's/^\(SUBDIRS = .\+\) tests /\1 /' Makefile
	echo skip > /dev/null
}

pre_make() {
	(cd glib &&
	${XMINGW}/cross make glibconfig.h.win32 &&
	${XMINGW}/cross make glibconfig-stamp &&
	mv glibconfig.h glibconfig.h.autogened &&
	cp glibconfig.h.win32 glibconfig.h) && 
	# gio\tests/dbus-* まわりで面倒なのでビルドしない。
	sed -i.orig -e "s/ tests\$/ #\0/" gio/Makefile
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	sed -i -e "s/^\(glib_genmarshal=\)\(glib-genmarshal\)/\1_\2/" "${INSTALL_TARGET}/lib/pkgconfig/glib-2.0.pc" &&
	cp gobject/_glib-genmarshal "${INSTALL_TARGET}/bin/." &&
	cp gio/_glib-compile-schemas "${INSTALL_TARGET}/bin/." &&
	cp gio/_glib-compile-resources "${INSTALL_TARGET}/bin/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll lib/charset.alias share/locale &&
	pack_archive "${__DEVZIP}" bin/_glib-* include lib/*.{def,a} lib/glib-2.0 lib/gio lib/pkgconfig share/aclocal share/glib-2.0/gettext share/bash-completion &&
	pack_archive "${__TOOLSZIP}" bin/*.exe bin/{gdbus-codegen,glib-gettextize,glib-mkenums} share/gdb share/glib-2.0/{gdb,schemas} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


