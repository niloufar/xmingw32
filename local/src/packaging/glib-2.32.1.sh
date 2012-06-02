#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=glib
VER=2.32.1
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	make clean 2>&1 > /dev/null
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
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
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
	# mingw の errno.h に定義されていないマクロをチェックしない。
	(patch --force --quiet -p 0 <<\EOF ; return 0) && 
--- glib/tests/fileutils.c.orig
+++ glib/tests/fileutils.c
@@ -541,9 +541,9 @@
   g_assert (g_file_error_from_errno (ENXIO) == G_FILE_ERROR_NXIO);
   g_assert (g_file_error_from_errno (ENODEV) == G_FILE_ERROR_NODEV);
   g_assert (g_file_error_from_errno (EROFS) == G_FILE_ERROR_ROFS);
-  g_assert (g_file_error_from_errno (ETXTBSY) == G_FILE_ERROR_TXTBSY);
+/*  g_assert (g_file_error_from_errno (ETXTBSY) == G_FILE_ERROR_TXTBSY);*/
   g_assert (g_file_error_from_errno (EFAULT) == G_FILE_ERROR_FAULT);
-  g_assert (g_file_error_from_errno (ELOOP) == G_FILE_ERROR_LOOP);
+/*  g_assert (g_file_error_from_errno (ELOOP) == G_FILE_ERROR_LOOP);*/
   g_assert (g_file_error_from_errno (ENOSPC) == G_FILE_ERROR_NOSPC);
   g_assert (g_file_error_from_errno (ENOMEM) == G_FILE_ERROR_NOMEM);
   g_assert (g_file_error_from_errno (EMFILE) == G_FILE_ERROR_MFILE);
EOF
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

run_pack_archive() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.dll lib/charset.alias share/locale &&
	pack_archive "${DEVZIP}" bin/_glib-* include lib/*.{def,a} lib/glib-2.0 lib/gio lib/pkgconfig share/aclocal share/glib-2.0/gettext share/gtk-doc &&
	pack_archive "${TOOLSZIP}" bin/*.exe bin/{gdbus-codegen,glib-gettextize,glib-mkenums} etc lib/gdbus-2.0 share/gdb share/glib-2.0/{gdb,schemas} share/man &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}" &&
	store_packed_archive "${TOOLSZIP}"
}


(

set -x

#DEPS=`latest --arch=${ARCH} zlib libffi gettext-runtime gettext-tools glib pkg-config`
#GETTEXT_RUNTIME=`latest --arch=${ARCH} gettext-runtime`
#ZLIB=`latest --arch=${ARCH} zlib`

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

run_expand_archive &&
cd "${DIRECTORY}" &&

pre_configure &&
run_configure &&
post_configure &&

pre_make &&
run_make &&

pre_pack &&
run_pack_archive &&

# testgdate
# testglib

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.

