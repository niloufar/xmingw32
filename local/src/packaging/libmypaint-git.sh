#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=libmypaint
	[ "" = "${VER}" ] && VER=git-b89de74
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/dep"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
json-c
EOS
}

optional_dependencies() {
	cat <<EOS
gegl
EOS
}

license() {
	cat <<EOS
ISC license

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	patch_adhoc -p 1 <<\EOS
--- libmypaint/gegl/Makefile.am.orig
+++ libmypaint/gegl/Makefile.am
@@ -73,6 +73,7 @@
 libmypaint_gegl_la_SOURCES = $(libmypaint_gegl_public_HEADERS) $(LIBMYPAINT_GEGL_SOURCES)
 
 libmypaint_gegl_la_CFLAGS = $(JSON_CFLAGS) $(GLIB_CFLAGS) $(GEGL_CFLAGS)
-libmypaint_gegl_la_LIBS = $(GEGL_LIBS)
+
+libmypaint_gegl_la_LDFLAGS = $(GEGL_LIBS) ../libmypaint.la
 
 endif # enable_gegl
EOS

	if [ ! -e configure ]
	then
		./autogen.sh
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --enable-gegl --enable-openmp --with-glib --enable-introspection=no
}

post_configure() {
	# shared ファイルを作ってくれない場合の対処。
	# libstdc++ を静的リンクする。
	bash ${XMINGW}/replibtool.sh shared static-libgcc
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	mkdir -p "${INSTALL_TARGET}/share/doc/libmypaint" &&
	cp COPYING "${INSTALL_TARGET}/share/doc/libmypaint/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/{doc,locale} &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



