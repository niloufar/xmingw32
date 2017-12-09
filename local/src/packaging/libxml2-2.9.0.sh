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
	MOD=libxml2
	[ "" = "${VER}" ] && VER=2.9.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/lang"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
iconv
EOS
}

optional_dependencies() {
	cat <<EOS
zlib
xz
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# 2.9.2: zlib, xz (liblzma) のチェックで LDFLAGS を置き換えないようにする。
	(patch_adhoc -p 0 <<\EOF; return 0)
--- configure.orig
+++ configure
@@ -12563,7 +12563,7 @@
 #define HAVE_ZLIB_H 1
 _ACEOF
  SAVE_LDFLAGS="${LDFLAGS}"
-	 LDFLAGS="-L${Z_DIR}/lib"
+#	 LDFLAGS="-L${Z_DIR}/lib"
 	{ $as_echo "$as_me:${as_lineno-$LINENO}: checking for gzread in -lz" >&5
 $as_echo_n "checking for gzread in -lz... " >&6; }
 if ${ac_cv_lib_z_gzread+:} false; then :
@@ -12723,7 +12723,7 @@
 #define HAVE_LZMA_H 1
 _ACEOF
  SAVE_LDFLAGS="${LDFLAGS}"
-	     LDFLAGS="-L${LZMA_DIR}/lib"
+#	     LDFLAGS="-L${LZMA_DIR}/lib"
             { $as_echo "$as_me:${as_lineno-$LINENO}: checking for lzma_code in -llzma" >&5
 $as_echo_n "checking for lzma_code in -llzma... " >&6; }
 if ${ac_cv_lib_lzma_lzma_code+:} false; then :
EOF
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --without-python --with-threads=native --disable-gtk-doc --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local NAME="${INSTALL_TARGET}/bin/xml2-config"
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${NAME}"
#	echo skip > /dev/null
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" bin/*-config include lib/*.{def,a} lib/xml2Conf.sh lib/pkgconfig share/man/man1/xml2-config.1 share/man/man3 share/{aclocal,doc,gtk-doc} lib/cmake/libxml2/libxml2-config.cmake &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1/xml{catalog,lint}.1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}


