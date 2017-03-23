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
	# package に返す変数。
	MOD=libwmf
	[ "" = "${VER}" ]   && VER=0.2.8.4
	[ "" = "${REV}" ]   && REV=1
	[ "" = "${PATCH}" ] && PATCH=8.1.debian
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__LIBNAME="libwmf"

	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${PATCH}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${PATCH}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${PATCH}-${REV}-tools_${ARCHSUFFIX}
}

# libxml2 のかわりに expat が使える。
dependencies() {
	cat <<EOS
freetype2
libpng
libxml2
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
gd
gdk-pixbuf
glib
jpeg
plot
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}" &&
	cd "${DIRECTORY}" &&
	name=`find_archive "${__ARCHIVEDIR}" ${__PATCH_ARCHIVE}` &&
	patch_debian "${__ARCHIVEDIR}/${name}" &&
	cd ..
}

run_patch() {
	# configure が -lpng 決め打ちで依存チェックしているのでごまかす。
	mkdir -p libpng &&
	ln -f -s ${XLIBRARY}/lib/include/libpng16 libpng/include &&
	mkdir -p libpng/lib &&
	ln -f -s ${XLIBRARY}/lib/lib/libpng16.dll.a libpng/lib/libpng.dll.a &&
	patch_adhoc -p 1 <<\EOF
--- libwmf-0.2.8.4.orig/src/ipa/ipa/bmp.h
+++ libwmf-0.2.8.4/src/ipa/ipa/bmp.h
@@ -66,7 +66,7 @@
 		return;
 	}
 
-	if (setjmp (png_ptr->jmpbuf))
+	if (png_jmpbuf (png_ptr))
 	{	WMF_DEBUG (API,"Failed to write bitmap as PNG! (setjmp failed)");
 		png_destroy_write_struct (&png_ptr,&info_ptr);
 		wmf_free (API,buffer);
EOF
	return 0
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` `${XMINGW}/cross pkg-config --cflags freetype2`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --with-libxml2 --without-expat --with-png=${PWD}/libpng --without-x --without-sys-gd --disable-gd --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# make で autoconf && automake してしまう。
	# aclocal.m4, configure.ac が更新されるため。
	sed -i.orig -e 's/^\(AUTOCONF = \).\+/\1 echo "autoconf"/' \
				-e 's/^\(AUTOMAKE = \).\+/\1 echo "automake"/' Makefile
	# shared ファイルを作ってくれない場合の対処。
	# -lpng に対し libtool が面倒事をおこすため mix を付けている。
	bash ${XMINGW}/replibtool.sh shared mix
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
local NAME="${INSTALL_TARGET}/bin/${__LIBNAME}-config"
	sed -i -e "s#^\s*\(prefix=\).*${INSTALL_TARGET}\$#\1\`dirname \$0\`/..#" "${NAME}"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/libwmf `find lib -name \*.dll` &&
	pack_archive "${__DEVZIP}" bin/libwmf-config include `find lib -name \*.a` &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} bin/libwmf-fontmap &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



